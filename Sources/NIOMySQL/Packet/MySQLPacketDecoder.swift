public struct MySQLPacketDecoder: ByteToMessageDecoder {
    public typealias InboundOut = MySQLPacket
    
    public let state: MySQLConnectionState
    
    public init(state: MySQLConnectionState) {
        self.state = state
    }
    
    public mutating func decode(ctx: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        var copy = buffer
        guard let header = copy.readInteger(endianness: .little, as: UInt32.self) else {
            return .needMoreData
        }
        // header = 01     00 00 01
        //          <seq>  <length>
        let length = header & 0x00_FF_FF_FF
        let sequenceID = header >> 24
        // print("header: \(header) length: \(length) seq: \(sequenceID)")
        guard let payload = copy.readSlice(length: numericCast(length)) else {
            return .needMoreData
        }
        buffer = copy
        let packet = MySQLPacket(payload: payload)
        self.state.currentSequenceID = UInt8(sequenceID & 0xFF)
        ctx.fireChannelRead(self.wrapInboundOut(packet))
        return .continue
    }
}
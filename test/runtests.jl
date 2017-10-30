using RippleXIPP
using Base.Test


#test packet
bytes = zeros(UInt8, sizeof(RippleXIPP.XippHeader))
append!(bytes, [UInt8(1), UInt8(3), UInt8(6)])
packet = RippleXIPP.XippPacket(bytes)
@test size(packet.header) == 0
@test packet.header.processor == 0
@test packet.payload == [UInt8(1), UInt8(3), UInt8(6)]

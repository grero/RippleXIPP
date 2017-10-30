using RippleXIPP
using Base.Test


#test packet
bytes = zeros(UInt8, sizeof(RippleXIPP.XippHeader))
append!(bytes, [UInt8(1), UInt8(3), UInt8(6)])
bytes[2] = UInt8(1)
packet = RippleXIPP.XippPacket(bytes)
@test size(packet.header) == 0
@test packet.header.processor == 1
@test packet.payload == [UInt8(1), UInt8(3), UInt8(6)]

#test conversion to data packet
bytes = zeros(UInt8, sizeof(RippleXIPP.XippHeader))
append!(bytes, [UInt8(2), UInt8(0), UInt8(0), UInt8(0), UInt8(1), UInt8(1)])
ppacket = RippleXIPP.XippPacket(bytes)
data_packet = RippleXIPP.XippDataPacket(ppacket)
@test data_packet.header == ppacket.header
@test data_packet.stream_type == 0x0002

#test conversion to continuous data packet
c_data_packet = RippleXIPP.XippContinuousDataPacket(data_packet)
@test c_data_packet.header == data_packet.header
@test c_data_packet.stream_type == data_packet.stream_type
@test c_data_packet.PADDING == 0
@test c_data_packet.i16 == [Int16(257)]

bytes = zeros(UInt8, sizeof(RippleXIPP.XippHeader))
append!(bytes, [UInt8(1), UInt8(3), UInt8(6)])
bytes[2] = UInt8(1)
packet = RippleXIPP.XippPacket(bytes)

#test socket
socket = RippleXIPP.create_receiving_socket(ip"127.0.0.1",2000)
packets = RippleXIPP.XippPacket[]
@sync begin 
    @async RippleXIPP.process_packets!(packets, socket)
    sock = UDPSocket()
    sleep(0.1)
    send(sock, ip"127.0.0.1", 2000, bytes)
    sleep(0.1)
    send(sock, ip"127.0.0.1", 2000, bytes)
    sleep(0.1)
    #send a packet indicating that we should stop
    bytes[2] = UInt8(0)
    send(sock, ip"127.0.0.1", 2000, bytes)
    close(sock)
    sleep(2.0)
    close(socket)
    sleep(0.1)
end
@test length(packets) == 2
@test packets[1] == packet
@test packets[2] == packet

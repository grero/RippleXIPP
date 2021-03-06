module RippleXIPP
using StaticArrays
import Base.size, Base.sizeof, Base.zero, Base.==, Base.rand, Base.convert, Base.unsafe_convert

const XIPP_STREAM_CONTINUOUS = UInt16(0x01)
const XIPP_STREAM_SEGMENT = UInt16(0x02)

immutable XippHeader
  _size::UInt8
  processor::UInt8
  _module::UInt8
  stream::UInt8
  _time::UInt32
end

Base.zero(::Type{XippHeader}) = XippHeader(UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt32(0))

function Base.sizeof(::Type{XippHeader})
    sizeof(UInt8)*4 + sizeof(UInt32)
end

Base.size(X::XippHeader) = X._size

immutable XippPacket
  header::XippHeader
  payload::Array{UInt8,1}
end


==(p1::XippPacket, p2::XippPacket) = ((p1.header == p2.header) && (p1.payload == p2.payload))

immutable XippTarget
  processor::UInt8
  _module::UInt8
  property::UInt16
end

immutable XippConfigPacket
  header::XippHeader
  target::XippTarget
  config::Array{UInt8,1}
end

immutable XippDataPacket
  header::XippHeader
  stream_type::UInt16
  count::UInt16
  data::Array{UInt8,1}
end

function XippDataPacket(packet::XippPacket)
    pp = pointer(packet.payload[1:2])
    stream_type = unsafe_load(convert(Ptr{UInt16}, pp))
    pp = pointer(packet.payload[3:4])
    count = unsafe_load(convert(Ptr{UInt16}, pp))
    XippDataPacket(packet.header, stream_type, count, packet.payload[5:end])
end

immutable XippContinuousDataPacket
  header::XippHeader
  stream_type::UInt16
  PADDING::UInt16
  i16::Array{Int16,1}
end

Base.size{T<:Union{XippPacket, XippDataPacket, XippContinuousDataPacket}}(packet::T) = 4*packet.header._size

function Base.zero(::Type{XippContinuousDataPacket})
    header = XippHeader(UInt8(19), UInt8(1), UInt8(1), UInt8(1), UInt32(0))
    data = zeros(Int16,32)
    XippContinuousDataPacket(header, XIPP_STREAM_CONTINUOUS, UInt16(0), data)
end

function XippContinuousDataPacket(packet::XippDataPacket)
    XippContinuousDataPacket(packet.header, packet.stream_type,
                             UInt16(0), reinterpret(Int16, packet.data))
end

#Wrap data in a packet
function XippContinuousDataPacket(data::SizedArray{Tuple{32}, Int16, 1,1},t::UInt32)
    n = 32
    _pad = UInt16(0)
    _size = 2 + 1 + 16  #header size is 8 bytes, so 2 32 bit units + 4 units for the data
    processor = 1 
    _module = 1
    _stream = 1
    _stream_type = XIPP_STREAM_CONTINUOUS
    header = XippHeader(_size, processor, _module, _stream, t)
    XippContinuousDataPacket(header, _stream_type, _pad, data)
end

function convert(::Type{Array{UInt8,1}}, packet::XippContinuousDataPacket)
    x = Array{UInt8}(4*packet.header._size)
    x[1] = packet.header._size
    x[2] = packet.header.processor
    x[3] = packet.header._module
    x[4] = packet.header.stream
    x[5:8] = reinterpret(UInt8, [packet.header._time])
    x[9:10] = reinterpret(UInt8, [packet.stream_type])
    x[11:12] = reinterpret(UInt8, [packet.PADDING])
    x[13:end] = reinterpret(UInt8, packet.i16)
    x
end

function unsafe_convert(::Type{Ptr{UInt8}}, packet::XippContinuousDataPacket)
    xx = convert(Array{UInt8,1}, packet)
    pointer(xx)
end


immutable XippSegmentDataPacket
  header::XippHeader
  stream_type::UInt16
  count::UInt16
  class_id::UInt16
  sample_cnt::UInt16
  i16::Array{Int16,1}
end

immutable XippLegacyDigitialDataPacket
  header::XippHeader
  stream_type::UInt16
  count::UInt16
  change_flag::UInt16
  parallel::UInt16
  event::SVector{4,UInt16}
end

immutable XippPropertyHeader
  vendor::UInt8
  _type::UInt8
  flags::UInt16
end

immutable XippBool
  header::XippPropertyHeader
  _value::UInt8
  _def::UInt8
end

function create_receiving_socket(address::IPAddr, port::Int64)
    udpsocket = UDPSocket()
    bind(udpsocket, address, port)
    udpsocket
end

function XippPacket(bytes::AbstractVector{UInt8})
    #first load the header
    p = pointer(bytes)
    header = unsafe_load(convert(Ptr{XippHeader}, p))
    #figure out the length of the packet by subtracting our the header
    offset = sizeof(XippHeader)
    payload = bytes[offset+1:4*header._size]
    XippPacket(header, payload)
end

function process_packets(socket::UDPSocket)
    packets = XippPacket[]
    process_packets!(packets, socket)
    packets
end

function process_packets!(packets::Array{XippPacket,1}, socket::UDPSocket)
    stop = false
    while !stop
        bytes = recv(socket)
        process_packets!(packets, bytes)
    end
end

function process_packets!(packets::Vector{XippPacket}, bytes::Vector{UInt8})
    n = length(bytes)
    i = 1
    while i <= n
        packet = XippPacket(view(bytes,i:n))
        #if packet.header.processor == 0
        #    stop = true
        #    break
        #end
        #check if the packet came from NIP
        if (packet.header.processor == 1) && (packet.header._module != 0)
            #check if it is data packet
            if packet.header.stream != 0
            data_packet = XippDataPacket(packet)
            if data_packet.stream_type == XIPP_STREAM_CONTINUOUS
                c_data_packet = XippContinuousDataPacket(data_packet)
            end
            end
        end
        push!(packets, packet)
        i += size(packet)
    end
end
include("sampler.jl")
include("server.jl")

end #module

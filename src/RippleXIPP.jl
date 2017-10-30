module RippleXIPP
using StaticArrays
import Base.size, Base.sizeof, Base.zero, Base.==

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

Base.size(packet::XippPacket) = sizeof(packet.header) + length(packet.payload)

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
  data::Array{UInt8,1}
end

immutable XippContinuousDataPacket
  header::XippHeader
  stream_type::UInt16
  PADDING::UInt16
  i16::Array{Int16,1}
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

function create_receiving_socket(address,port)
    udpsocket = UDPSocket()
    bind(udpsocet, address, port)
    updsocket
end

function XippPacket(bytes::Array{UInt8})
    #first load the header
    p = pointer(bytes)
    header = unsafe_load(convert(Ptr{XippHeader}, p))
    #figure out the length of the packet by subtracting our the header
    payload = bytes[sizeof(XippHeader)+1:end]
    XippPacket(header, payload)
end

end #module


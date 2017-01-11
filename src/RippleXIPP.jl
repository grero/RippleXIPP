module RippleXIPP
using FixedSizeArrays
import Base.size

immutable XippHeader
  _size::UInt8
  processor::UInt8
  _module::UInt8
  stream::UInt8
  _time::UInt32
end

Base.size(X::XIPPHeader) = X._size

immutable XippPacket
  header::XippHeader
  payload::Array{UInt8,1}
end

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
  event::Vec{4,UInt16}
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


end #module


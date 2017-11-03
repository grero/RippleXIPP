"""
Send random packets of continuous data
"""
function serve(address::IPAddr, port::Int)
    socket = UDPSocket()
    t0 = time()
    incr = UInt32(32)
    data = Size(32)(zeros(Int16, incr))
    generate_data!(data)
    while true
        t = round(UInt32, 1e6*(time() - t0))
        packet = RippleXIPP.XippContinuousDataPacket(data, t)
        packet_data = convert(Array{UInt8,1}, packet)
        send(socket, address, port, unsafe_string(pointer(packet_data), length(packet_data)))
        generate_data!(data)
        sleep(0.001)
    end
end

function generate_data!(data::SizedArray{Tuple{32}, Int16, 1,1})
    n = 32
    for i in 1:n
        Δx = round(Int16, 10*randn())
        data[i] .+= Δx
    end
end

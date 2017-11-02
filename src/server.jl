"""
Send random packets of continuous data
"""
function serve(address::IPAddr, port::Int)
    socket = UDPSocket()
    t0 = UInt32(0)
    incr = UInt32(32)
    data = zeros(Int16, incr)
    generate_data!(data)
    while true
        packet = RippleXIPP.XippContinuousDataPacket(data, t0)
        t0 += incr
        send(socket, address, port, packet)
        generate_data!(data)
        sleep(0.01)
    end
end

function generate_data!(data::Array{Int16,1})
    n = length(data)
    for i in 1:n
        Δx = round(Int16, 10*randn())
        data[i] .+= Δx
    end
end

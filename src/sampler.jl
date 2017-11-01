function get_continuous_data(socket::UDPSocket, time_window::Float64)
    t0 = 0.0
    data = Array{Int16}(0) 
    while t0 < time_window
        bytes = recv(socket)
        n = length(bytes)
        i = 1
        while i <= n
            packet = XippPacket(bytes[i:end])
            if (packet.header.processor == 1) && (packet.header._module != 0)
                if packet.header.stream != 0
                    data_packet = XippDataPacket(packet)
                    if data_packet.stream_type == XIPP_STREAM_CONTINUOUS
                        c_data_packet = XippContinuousDataPacket(data_packet)
                        t0 += length(c_data_packet.i16)/30.0 #convert to ms
                        append!(data, c_data_packet.i16)
                    end
                end
            end
            i += size(packet)
        end
    end
    data
end

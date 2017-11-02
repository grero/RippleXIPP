function get_continuous_data(socket::UDPSocket, time_window::Float64)
    t0 = 0.0
    t1 = 0.0
    data = Array{Int16}(0) 
    source_module = Array{UInt8}(0)
    while (t1-t0) < time_window
        bytes = recv(socket)
        n = length(bytes)
        i = 1
        while i <= n
            packet = XippPacket(view(bytes,i:n))
            if (packet.header.processor == 1) && (packet.header._module != 0)
                if packet.header.stream != 0
                    data_packet = XippDataPacket(packet)
                    if data_packet.stream_type == XIPP_STREAM_CONTINUOUS
                        c_data_packet = XippContinuousDataPacket(data_packet)
			t0 = t1
                        t1 = float(packet.header._time)
                        append!(data, c_data_packet.i16)
			append!(source_module, c_data_packet.header_module)
                    end
                end
            end
            i += size(packet)
        end
    end
    data, source_module
end

using PyPlot
#TODO: Use the new MakiE instead of pyplot
using RippleXIPP
using DSP

function show_data(socket)
    data,mm = RippleXIPP.get_continuous_data(socket, 1.0e5)
    fig = plt[:figure]()
    ax = fig[:add_subplot](111)
    ll = ax[:plot](1:length(mm), data[1:32:end])[1]
    try
        while true
            data,mm = RippleXIPP.get_continuous_data(socket, 1.0e5)
            y = data[1:32:end]
            ll[:set_data](1:length(mm), y)
            ax[:set_ylim](minimum(y), maximum(y))
            ax[:set_xlim](1,length(mm))
            fig[:canvas][:draw]()
            yield()
        end
    catch ex
    finally
        plt[:close](fig)
    end
end

function show_periodogram(socket::UDPSocket, channel=1;fs=30_000.0)
    data,mm = RippleXIPP.get_continuous_data(socket, 10.0e5)
    SS = DSP.Periodograms.spectrogram(data[channel:32:end]-mean(data[1:32:end]);fs=fs)
    fig = plt[:figure]()
    ax = fig[:add_subplot](111)
    II = ax[:imshow](log10.(SS.power);origin="lower", extent=(0, size(SS.power,2)-1, SS.freq[1], SS.freq[end]),aspect="auto")
    while true
        data,mm = RippleXIPP.get_continuous_data(socket, 10.0e5)
        show_periodogram(fig, data[channel:32:end];fs=fs)
    end
end

function show_periodogram(fig, data;fs=30_000.0)
    SS = DSP.Periodograms.spectrogram(data - mean(data);fs=fs)
    ax = fig[:axes][1]
    II = ax[:images][1]
    II[:set_data](log10.(SS.power))
    fig[:canvas][:draw]()
    yield()
end

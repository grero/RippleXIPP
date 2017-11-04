using RippleXIPP
using GeometryTypes, GLAbstraction, GLVisualize
using Colors
using Reactive

function show_data(socket, channel=1)
    window = glscreen()
    res = widths(window)
    w,h = res
    xmargin = 20
    ymargin = 20
    ticks = loop(1:10,60)
    data = map(ticks) do tt
        dd,mm = RippleXIPP.get_continuous_data(socket, 5.0e5)
        y = dd[channel:32:end]
        Δx = (w-2*xmargin)/length(y)
        y0 = minimum(y)
        y1 = maximum(y)
        Δy = (h-2*ymargin)/(y1-y0)#this is completely arbitrary
        [Point2f0(xmargin + i*Δx, ymargin + (y[i]-y0)*Δy) for i in 1:length(y)]
      end

      acolor = map(data) do dd 
          [RGBA(1.0, 0.0, 0.0, 1.0) for x in 1:length(dd)]
      end
      #q = map(data) do dd
      #    println(extrema(dd))
      #end
      _view(visualize(data, :lines, color=acolor), window)
      renderloop(window)
end

function show_data(ss::Signal{RippleXIPP.XippContinuousDataPacket}, channel=1, ymin=-10_00, ymax=10_000)
    window = glscreen()
    res = widths(window)
    w,h = res
    xmargin = 20
    ymargin = 20
    Δx = (w-2*xmargin)/30_000
    Δy = (h-2*ymargin)/(ymax-ymin)
    dt = 30
    data = [Point2f0(xmargin + i*Δx, 0.0f0) for i in 1:30_000]
    const tm = typemax(UInt32)
    t0 = tm
    tp = 1
    tick = bounce(1:10, 100)
    new_data = map(ss) do _ss
        t1 = _ss.header._time
        if t0 == tm
            t0 = t1
        end
        tt = mod(div(t1 - t0,500) + 1, 30_000)+1
        _dd = _ss.i16[channel]
        for k in tp:tt
            data[k] = Point2f0(xmargin + k*Δx, ymargin + (Float32(_dd) - ymin)*Δy)
        end
        tp = tt
        data
    end
    plot_data = sampleon(tick, new_data)
    _view(visualize(plot_data, :lines, color=RGBA(1.0, 0.0, 0.0, 1.0)), window)
    renderloop(window)
end

function test()
    socket = RippleXIPP.create_receiving_socket(ip"127.0.0.1", 2003)
    packet = zero(RippleXIPP.XippContinuousDataPacket)
    ss = Signal(packet)
    ss, socket
end

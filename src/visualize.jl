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

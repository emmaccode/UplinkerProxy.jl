module UplinkerProxy
using ChiProxy
using ChiProxy.Toolips: IP4, get_ip, get_ip4, style!, Connection, write!, get_route
using ChiProxy.Toolips.Components: percent, pt
served_cached = div("cachemsg", text = """chifidocs is currently offline; you are viewing a cached 
    version of the site. Some functionality might be missing. Click this message to try for a live version of
     chifidocs again.""", 
onclick="location.href='https://chifidocs.com'", align = "center")

style!(served_cached, "padding" => 2percent, "background-color" => "#1e1e1e", "color" => "white",          
"font-weight" => "bold", "cursor" => "pointer", "position" => "fixed", "top" => 95percent, "height" => 3percent, 
"width" => 96percent, "left" => 0percent)

MAIN_PROX = ChiProxy.backup_proxy_route("chifidocs.com", "192.168.1.28":8000, served_cached) do c::Connection
    write!(c, "unable to reach chifidocs, and no cache of $(get_route(c)) available")
end

MEMCODE::String = ""

function start(ip::IP4 = "127.0.0.1":8000, uplinker_ip::IP4 = "127.0.0.1":8001; noup::Bool = false)
    ChiProxy.start(ip, MAIN_PROX)
    if noup return end
    ChiProxy.Toolips.start!(:TCP, UplinkerProxy, uplinker_ip)
end

uplinker_handler = ChiProxy.Toolips.Handler() do c::ChiProxy.Toolips.SocketConnection
    sent_bytes = String(readavailable(c))
    rq_type = ["S", "I"][parse(Int64, sent_bytes[1])]
    if rq_type == "S"
        @info "did memcode rq type"
        ob_nb = split(sent_bytes[2:end], "|")
        if UplinkerProxy.MEMCODE == ""
            UplinkerProxy.MEMCODE = string(ob_nb[1])
            @info "memcode set first time"
            return
        end
        if ob_nb[2] == UplinkerProxy.MEMCODE
            UplinkerProxy.MEMCODE = string(ob_nb[1])
            @info "memcode set"
        end
    elseif rq_type == "I"
        @info "got I rqtype"
        code_set = split(sent_bytes[2:end], "|")
        if code_set[1] == UplinkerProxy.MEMCODE
            MAIN_PROX.src[:to] = IP4(get_ip(c), parse(UInt16, code_set[2]))
            @info "set ip $(get_ip(c))"
        else
            @warn UplinkerProxy.MEMCODE
            @warn code_set[1]
        end
    end
end

export uplinker_handler
end # module UplinkerProxy

module UplinkerProxy
using ChiProxy
using ChiProxy.Toolips: IP4, get_ip, get_ip4
MAIN_PROX = proxy_route("chifidocs.com", "192.168.1.20":8000)
MEMCODE::String = ""

function start(ip::IP4 = "127.0.0.1":8000, uplinker_ip::IP4 = "127.0.0.1":8001)
    ChiProxy.start(ip, MAIN_PROX)
    ChiProxy.Toolips.start!(:TCP, UplinkerProxy, uplinker_ip)
end

uplinker_handler = ChiProxy.Toolips.TCPHandler() do c::ChiProxy.Toolips.SocketConnection
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
            MAIN_PROX.ip = IP4(get_ip(c), parse(UInt16, code_set[2]))
            @info "set ip $(get_ip(c))"
        else
            @warn UplinkerProxy.MEMCODE
            @warn code_set[1]
        end
    end
end

export uplinker_handler
end # module UplinkerProxy

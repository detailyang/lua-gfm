local lpeg = require("lpeg")

local P = lpeg.P
local S = lpeg.S
local R = lpeg.R
local C = lpeg.C
local V = lpeg.V
local Cc = lpeg.Cc
local Cf = lpeg.Cf
local Cg = lpeg.Cg
local Ct = lpeg.Ct
local Cb = lpeg.Cb
local Cmt = lpeg.Cmt
local match = lpeg.match
local sf = string.format


local to_header_dom = function(n)
    return function(s)
        return sf("<h%d>%s</h%d>", n, s, n)
    end
end


local table_concat = function(t)
    return table.concat(t)
end


local table_length = function(t)
    return #t
end


local to_header_dom = function(n)
    local prefix = string.rep("#", n)
    return P(prefix) * C((1 - V"nl")^1) / function(s)
        return string.format("<h%d>%s</h%d>", n, s, n)
    end
end


local to_codeblack_dom = function()
    return P"```" * (S"\t " ^ 0)
           * Ct(Cg(P(1 - V"nl") ^ 0, "lang")
           * Cg(P(1 - P"```") ^ 0, "code"))
           / function(t)
            return string.format("<code id=\"%s\">%s</code>", t["lang"], t["code"])
           end
           * P "```"
end


local to_thead_dom = function(s, a, b, t)
    local d = {}
    d[1] = "<table><thead><tr>"
    d[2] = string.format("<th>%s</th>", a)
    for k, v in pairs(t) do
        d[#d + 1] = string.format("<th>%s</th>", v)
    end

    d[#d + 1] = "</tr></thead>"

    return table.concat(d)
end


local to_td_dom = function(s)
    return string.format("<td>%s</td>", s)
end


local grammer = P{
    "markdown";
    markdown = (V"h6" + V"h5" + V"h4"
                + V"h3" + V"h2" + V"h1"
                + V"lists" + V"blockquote"
                + V"codeblock" + V"tables" + V"nl") ^ 0,
    nl = P"\r" ^ -1 * P"\n",
    w = S"\t ",
    leastw = V"w" ^ 1,
    h1 = to_header_dom(1),
    h2 = to_header_dom(2),
    h3 = to_header_dom(3),
    h4 = to_header_dom(4),
    h5 = to_header_dom(5),
    h6 = to_header_dom(6),
    lists = V"ul" + V"ol" + V"tl",
    ul = Ct(Cc"<ul>" * (V"ui" * V"nl")^ 1 * Cc"</ul>") / table_concat,
    ui = P"*" * V"leastw" * Ct(Cc"<li>" * C((1 - V"nl") ^ 1) * Cc"</li>") / table_concat,
    ol = Ct(Cc"<ol>" * (V"oi" * V"nl")^ 1 * Cc"</ol>") / table_concat,
    oi = R"09"^1 * P"." * V"leastw" * Ct(Cc"<li>" * C((1 - V"nl") ^ 1) * Cc"</li>") / table_concat,
    tl = Ct(Cc"<ul>" * (V"ti" * V"nl") ^ 1 * Cc"</ul>") /table_concat,
    ti = V"titodo" + V"tidone",
    titodo = P"-" * V"leastw" * P"[ ]" * Ct(Cc"<li><input checked=\"false\">"
                  * C(P(1 - V"nl") ^ 0) * Cc"</li>") / table_concat,
    tidone = P"-" * V"leastw" * P"[x]" * Ct(Cc"<li><input checked=\"true\">"
                  * C(P(1 - V"nl") ^ 0) * Cc"</li>") / table_concat,
    blockquote = P">" * V"leastw" * Cc"<blockquote>" * C(P(1 - V"nl" ^ 2) ^ 1) * Cc"</blockquote>",
    codeblock = to_codeblack_dom(),
    tables =  V"thead" * V"nl" * V"tneck" * (V"nl" ^ -1) * Cmt(Cb("thead") * Cb("tneck"), function(s, i, a, b)
        return #a == #b
    end) * Cb("thead") / to_thead_dom * V"tbodys" ^ 0 *Cc"</table>",
    thead = C(C((1 - P"|" - V"nl") ^ 1)) * Cg(Ct((P"|" * C(P(1 - P"|" - V"nl") ^ 1)) ^ 0), "thead"),
    tneck = C(S"- " ^ 1) * Cg(Ct((C(P"|" * S"- " ^ 1)) ^ 0), "tneck"),
    tbodys = V"tbody" ^ 1,
    tbody = Cc"<tbody><tr>" * (C((1 - P"|" - V"nl") ^ 1) * P"|" / function(s)
        return string.format("<td>%s</td>", s)
    end) * (C((1 - P"|" - V"nl") ^ 1) / to_td_dom) ^ -1 * Cc"</tr></tbody>"
}


local s = [==[
First Header|Second Header
------------|-------------
Content from cell 1|Content from cell 2
Content in the first column|Content in the second column
]==]
local t = Ct(grammer):match(s)

print(table.concat(t))
for k, v in pairs(t) do
    print('k', k)
    print('v', v)
end

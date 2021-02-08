local list = require "lib/list"


local fixture = {}
local test = {}

function fixture.numbers()
  return list{12,54,23.4,765,4,11,8.64,5000}
end
function fixture.strings()
  return list{"foo", "bar", "stuff", "length", "idea"}
end

function fixture.num_str()
  return list{12,"foo",54,"stuff",5000,"length"}
end

function fixture.lists()
  return list{list{5,4,3,2}, list{"stuff","things"}, list{10,"foo",23.3,"bar"}}
end

function fixture.tables()
  return list{{5,4,3,2,['abc']='jerry'}, {"stuff","things",['abc']=123}, {10,["foo"]="hungry",23.3,"bar"}}
end

function fixture.num_str_tables()
  return list{86, 7, "stuff", {5,4,3,2,['abc']='jerry'}, "have", 10, 9.8, {"stuff","things",['abc']=123}, {10,["foo"]="hungry",23.3,"bar"}, 100}
end

function fixture.recursive()
  return list{86, 7, "stuff", {5,{"high", "low", 1023},3,2,['abc']='jerry'}, "have", 10, 9.8, {"stuff","things",['abc']=123,{high="up", low="down", 1023}}, {{high={100,80}, low={10,5}, 1023},["foo"]="hungry",23.3,"bar"}, 100}
end

function test.tostring()
  print("TEST STRING")
  for _,v in pairs(fixture) do
    print(v())
  end
  print()
end
--[[
function test.equality()
  print("TEST EQ")
  for _,s in pairs(fixture) do
    for _,v in pairs(fixture) do
      print(s(),"==",v())
      print(s() == v())
    end
  end
  print()
end]]

function test.table_eq()
  print("TEST TABLE EQ")
  for _,s in pairs(fixture) do
    for _,v in pairs(fixture) do
      print(s(),"==",v())
      print(table.equal(s(), v()))
    end
  end
  print()
end
--[[
function test.concat()
  for _,v in pairs(fixture) do
    for _,v in pairs(fixture) do
      print(v() .. v())
    end
  end
end]]

for _,v in pairs(test) do
  v()
end


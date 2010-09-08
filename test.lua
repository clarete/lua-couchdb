package.path = package.path .. ';/home/lincoln/Work/MinC/Videre/videre/src/?.lua'

require("couchdb")
require("util")

session = couchdb.Session:new()
db = couchdb.Database:new(session, "db1")
for _, v in pairs(session:all_dbs()) do
   v:delete()
end

pprint(session:all_dbs())

db:create()
pprint(session:all_dbs())

doc = couchdb.Document:new{id="blah", title="Rafael", age=18}
pprint(doc.id) --> blah

db:put(doc)
pprint(doc.id) --> not nil

doc2 = couchdb.Document:new{Name="Thiago", age=28}
pprint(doc2.id) --> nil

db:put(doc2)
pprint(doc2.id) --> not nil

doc3 = couchdb.Document:new{Name="Lincoln", age=23}
pprint(doc3.id) --> nil

db:put(doc3)
pprint(doc3.id) --> not nil

docs = db:all_docs()
pprint(docs)

db:delete_doc(doc3)
pprint(doc3.id)

docs = db:all_docs()
pprint(docs)

--db:delete()
--pprint(session:all_dbs())

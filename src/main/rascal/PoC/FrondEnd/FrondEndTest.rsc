module PoC::FrondEnd::FrondEndTest

import util::Webserver;

import Content;

test bool testWebServer() {
   loc testLoc = |http://localhost:10001|;
   
   // simple get
   //Response testServer(get("/hello")) = response("hello world!");
   Content cont = html("\<a href=\"http://www.rascal-mpl.org\"\>Rascal homepage\</a\>");
   //Response testServer(p:post("/upload8", value (type[value] _) stuff)) = response("uploaded: <p.parameters["firstname"]> <stuff(#value)>");   
   
   try {
      serve(testLoc, cont.response);
      //serve(testLoc, testServer);

      return true;
   }
   catch value exception:
     throw exception;
   finally {
     shutdown(testLoc);
   }
}
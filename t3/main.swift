//
//  main.swift
//  t3
//
//  Created by bill donner on 12/2/23.
//

import Foundation
import q20kshare
import ArgumentParser

struct QuestionsModelEntry {
  let question:String
  let answers:[String]
  let correct:String
  let explanation:String
  let hint:String
}
struct QuestionsModelResponse {
  let questions:[QuestionsModelEntry]
  
}

// Function to call the OpenAI API
func callOpenAI(APIKey: String,semaphore:DispatchSemaphore, model:String, systemMessage: String, userMessage: String) {
  // Construct the API request payload

  let baseURL = "https://api.openai.com/v1/chat/completions"
  let headers = ["Authorization": "Bearer \(APIKey)","Content-Type":"application/json"]
  let parameters = [
    "model":model,
    "max_tokens": 4000,
    //        "top_p": 1,
    //        "frequency_penalty": 0,
    //        "presence_penalty": 0,
    "temperature": 0.7,
    "messages": [
      ["role": "system", "content": systemMessage],
      ["role": "user", "content": userMessage]
    ]
  ] as [String : Any]
  var jsonData:Data
  do {
    // Convert the parameters to JSON data
    jsonData = try JSONSerialization.data(withJSONObject: parameters)
  } catch {
    fatalError("Could not serialize")
  }
  // print("sending ... ", String(data:jsonData,encoding: .utf8) ?? "")
  
  // Make the API request
  var request = URLRequest(url: URL(string: baseURL)!)
  request.httpMethod = "POST"
  request.allHTTPHeaderFields = headers
  request.httpBody = jsonData
  
  
  URLSession.shared.dataTask(with: request) { (data, response, error) in
   
    
    if let error = error {
      print("API request error: \(error)")
      return
    }
    
    guard let data = data else {
      print("API response data is empty")
      return
    }
    
    // Parse the API response JSON
    do {
      let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
      guard let json = json  else { fatalError("jsonjson")}
      guard let choices = json["choices"] as? [Any]  else { print(json); fatalError("choiceschoices")}
      guard let firstChoice = choices.first as? [String: Any] else {fatalError("firstfirst")}
      guard let reply = firstChoice["message"] as? [String: Any] else {fatalError("replyreply")}
      guard let content = reply["content"] as? String else {fatalError("contentcontent")}
      
      print(">assistant:\n")
      print("\(content)")
      
      semaphore.signal()
    }
    catch {
      print("response serializationthrown with error \(error)")
    }
  }.resume()
}
// Define a struct to hold the command line arguments
struct T3: ParsableCommand   {
  static var configuration = CommandConfiguration(
    abstract: "Pump One Cycle",
    discussion: "choose LLM and run one chat cycle",
    version: "0.3.2")
  
  
  @Option(help: "system template")
  var sysurl: String
  
  @Option( help:"user template")
  var usrurl: String
  
  @Option( help:"model")
  var model: String
  
  @Option( help:"listmodels")
  var listmodels: String = ""
  
  mutating func run() throws {
    
    
    do {
      
      let apiKey = try getAPIKey()
      
      guard listmodels.count==0 else {
        listModels(apiKey: apiKey)
        return
      }
      
      guard let sys = URL(string:sysurl) else {
        fatalError("Invalid system template URL")
      }
      guard let usr = URL(string:usrurl) else {
        fatalError("Invalid user template URL")
      }
      let chatmodel:String =  model != "" ?   model : "gpt-0613"
      
      
      let sysdata = try Data(contentsOf:sys)
      guard let systemMessage = String(data:sysdata,encoding: .utf8) else {
        fatalError("Cant decode system template")
      }
      let usrdata = try Data(contentsOf:usr)
      guard let usrMessage = String(data:usrdata,encoding: .utf8) else {
        fatalError("Cant decode user template")
      }

      print(">Calling ChatGPT \(chatmodel)")
      print("system: ",systemMessage)
      let time1 = Date()
      var i = 0
      let tmsgs = usrMessage.components(separatedBy: "*****")
        let umsgs = tmsgs.compactMap{$0.trimmingCharacters(in: .whitespacesAndNewlines)}
      umsgs.forEach { umsg in
        i += 1
        print("\n=========== Task \(i) ============")
        print("\n>user: ",umsg)
        
        let semaphore = DispatchSemaphore(value: 0)
        callOpenAI(APIKey: apiKey,
                   semaphore:semaphore,
                   model: chatmodel,
                   systemMessage:  systemMessage,
                   userMessage: umsg)
        
        semaphore.wait()
        let elapsed = Date().timeIntervalSince(time1)
        print(">ChatGPT \(chatmodel) returned in \(elapsed) secs")
      }
    }
    
    catch {
      print("Error -> \(error)")
    }
  }
}


T3.main()



struct ModelEntry: Codable {
  let id: String
  let object: String
  let created: Date
  let owned_by: String
}
struct ModelResponse: Codable {
  let object: String
  let data: [ModelEntry]
}

func listModels(apiKey:String) {
  
  guard let url = URL(string: "https://api.openai.com/v1/models") else {
    return
  }
  
  var request = URLRequest(url: url)
  request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
  let semaphore = DispatchSemaphore(value: 0)
  defer { semaphore.signal() }
  let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
    guard let data = data, error == nil else {
      print("Error: \(error?.localizedDescription ?? "Unknown error")")
      return
    }
    
    do {
      
      //          print("decode slow",String(data:data,encoding:.utf8) ?? "??")
      let modelresponse = try JSONDecoder().decode(ModelResponse.self, from: data)
      let models = modelresponse.data.sorted {$0.id<$1.id}
      for model in models{
        print("\(model.id) \(model.owned_by)")
      }
    } catch {
      print("Error decoding response: \(error)")
    }
  }
  
  task.resume()
  semaphore.wait()
}

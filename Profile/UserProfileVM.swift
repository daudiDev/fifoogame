//
//  UserProfileVM.swift
//  Fifoo
//
//  Created by Daudi Sagala on 5/27/24.
//
import Foundation
import SwiftUI


class UserProfileVM: ObservableObject {
    @Published var username: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var phone: String = ""
    @Published var joined:  String = ""
    @Published var imageUrl: String = ""
    @Published var changeResponse: String = ""
    @Published var lastActive: String = ""
    @Published var inFollowersCount: Int = 0
    @Published var outFollowersCount: Int = 0
    @Published var topTipster: Bool = false
    @Published var topRequester: Bool = false
    @Published var topResponder: Bool = false
    @Published var topContributor: Bool = false
    @Published var tipsCount: Int = 0
    @Published var responseCount: Int = 0
    @Published var requestCount: Int = 0
    @Published var unreadMessages: Int

   
    
    init(username: String, firstName: String, lastName: String, phone: String, joined:  String, imageUrl: String, changeResponse: String, lastActive: String, inFollowersCount: Int, outFollowersCount: Int, topTipster: Bool, topRequester: Bool, topResponder: Bool, topContributor: Bool, tipsCount: Int, responseCount: Int, requestCount: Int, unreadMessages: Int) {
        self.username          = username
        self.firstName         = firstName
        self.lastName          = lastName
        self.phone             = phone
        self.joined            = joined
        self.imageUrl          = imageUrl
        self.changeResponse    = changeResponse
        self.lastActive        = lastActive
        self.inFollowersCount  = inFollowersCount
        self.outFollowersCount = outFollowersCount
        self.topTipster        = topTipster
        self.topRequester      = topRequester
        self.topResponder      = topResponder
        self.topContributor    = topContributor
        self.tipsCount         = tipsCount
        self.responseCount     = responseCount
        self.requestCount      = requestCount
        self.unreadMessages    = unreadMessages
 
    }
    
 
    func editProfile(username: String, firstName: String, lastName: String, phone: String, imageUrl:  String) {
     
        let defaults = UserDefaults.standard
        guard let token = defaults.string(forKey: "jsonWebToken") else {
            return
        }

        guard let userId = defaults.string(forKey: "userId") else {
            return
        }

        var components = URLComponents(string: Urls.updateProfileUrl)

        components?.queryItems = [
            URLQueryItem(name: "user_id", value: userId)
        ]

        guard let url = components?.url else {

            return
        }

        let body = EditProfile(username: username,
                               firstName: firstName,
                               lastName: lastName,
                               phone: phone,
                               imageUrl: imageUrl)

        var request = URLRequest(url: url);
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) {data,_,error in

            guard let data = data, error == nil else {
                return
            }
            
            do {
                
                let userProfileResponse = try JSONDecoder().decode(EditProfileResponse.self, from: data)
                
                DispatchQueue.main.async {
                    self.changeResponse = userProfileResponse.message
                }
                
            } catch {
                print(error)
            }
            

        }.resume()


    }

    func cancelAccount(level: String) {

        let defaults = UserDefaults.standard
        guard let token = defaults.string(forKey: "jsonWebToken") else {
            return
        }

        guard let userId = defaults.string(forKey: "userId") else {
            return
        }

        var components = URLComponents(string: Urls.cancelProfileUrl)

        components?.queryItems = [
            URLQueryItem(name: "user_id", value: userId)
        ]

        guard let url = components?.url else {

            return
        }

        let body = CancelProfileBody(level: level)

        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) {data,_,error in

            guard let data = data, error == nil else {
                return
            }
            
        
            
            do {
                
                let userProfileResponse = try JSONDecoder().decode(EditProfileResponse.self, from: data)
                
                DispatchQueue.main.async {
                    self.changeResponse = userProfileResponse.message
                }
                
            } catch {
                print(error)
            }

        }.resume()
        
    }
    
}


struct EditProfile: Codable {
    let username: String
    let firstName: String
    let lastName: String
    let phone: String
    let imageUrl: String
}

struct CancelProfileBody: Codable {
    let level: String
}

struct EditProfileResponse: Codable {
    let message: String
}

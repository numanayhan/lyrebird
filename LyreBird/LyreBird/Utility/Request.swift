//
//  Request.swift
//  LyreBird
//
//  Created by Melike Büşra Ayhan on 5.09.2020.
//  Copyright © 2020 com.lyrebird. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

protocol RequestDataDelegate {
    func didCompleteRequest(result: String)
}

class Request  {
    
    static let defaultService = Request()
    var delegate = RequestDataDelegate.self
    
    func  ConnectionRequest(api :String,parameters:Parameters  , completion: @escaping (Any?) ->Void)
    {
        
        Alamofire.request(api , method: .post, parameters: parameters, encoding: URLEncoding.default).responseJSON(completionHandler: { (response ) in
            switch (response.result){
            case .success(_):
                if let data = response.result.value{
                    let jsonObject:NSDictionary = data as! NSDictionary
                    completion((jsonObject))
                }
                break
            case .failure(_):
                if let data = response.result.value{
                    let jsonObject:NSDictionary = data as! NSDictionary
                    completion((jsonObject))
                }
                break
            }
            return
            
        })
    }
    
    func  ConnectionRequestHistory(api :String,parameters:Parameters  , completion: @escaping (Any?) ->Void)
    {
        
        Alamofire.request(api , method: .get, parameters: parameters, encoding: URLEncoding.default).responseJSON(completionHandler: { (response ) in
            switch (response.result){
            case .success(_):
                
                if let data = response.result.value{
                    let jsonObject = data
                    completion((jsonObject))
                    
                }
                break
                
            case .failure(_):
                if let data = response.result.value{
                    let jsonObject:NSDictionary = data as! NSDictionary
                    completion((jsonObject))
                }
                break
            }
            
            
            return
            
        })
        
        
    }
    func  getRequest(api :String  , completion: @escaping (Any?) ->Void)
    {
        
        Alamofire.request(api , method: .get, encoding: URLEncoding.default).responseJSON(completionHandler: { (response ) in
            switch (response.result){
            case .success(_):
                if let data = response.data{ 
                    completion((data))
                }
                break
                
            case .failure(_):
                if let data = response.result.value{
                    let jsonObject:NSDictionary = data as! NSDictionary
                    completion((jsonObject))
                }
                break
            }
            return
            
        })
        
        
    }
    func  getRequestParams(API :String ,parameters:Parameters , completion: @escaping (Any?) ->Void)
    {
        
        Alamofire.request(API, method: .get,parameters: parameters, encoding: URLEncoding.default).responseJSON(completionHandler: { (response ) in
            switch (response.result){
            case .success(_):
                
                if let data = response.result.value{
                    let jsonObject = data
                    completion((jsonObject))
                    
                }
                break
                
            case .failure(_):
            if let data = response.result.value{
                let jsonObject:NSDictionary = data as! NSDictionary
                completion((jsonObject))
                }
                
                break
            }
            return
            
        })
        
        
    }
}

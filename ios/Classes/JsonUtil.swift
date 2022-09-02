//
//  JsonUtil.swift
//  AppAuth
//
//  Created by LondonX on 2022/9/2.
//

import Foundation

public class JsonUtil {
    public static func convertToDictionary(text: String?) -> [String: Any]? {
        if (text == nil) {
            return nil
        }
        if let data = text!.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }

    public static func getArrayFromJSONString(text: String?) -> NSArray? {
        if (text == nil) {
            return nil
        }
        let jsonData = text!.data(using: .utf8)
        if(jsonData == nil) {
            return nil
        }
        let array = try? JSONSerialization.jsonObject(with: jsonData!, options: .mutableContainers)
        if (array == nil) {
            return nil
        }
        return array! as? NSArray
    }
}

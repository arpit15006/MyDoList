//
//  ListDataModel.swift
//  MyDoList
//
//  Created by Arpit Patel on 04/12/25.
//CRUD Operations

import Foundation
import SwiftData

@Model
class DoList{
    var title: String
    
    init(title:String){
        self.title=title
    }
}


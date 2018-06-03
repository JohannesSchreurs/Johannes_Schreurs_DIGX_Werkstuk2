//
//  Station.swift
//  Johannes_Schreurs_Werkstuk2
//
//  Created by Johannes Schreurs on 31/05/2018.
//  Copyright © 2018 Johannes Schreurs. All rights reserved.
//

import Foundation
import MapKit
import UIKit

class MyStation: NSObject, MKAnnotation{
   
    var number: Int64?
    var name: String?
    var address: String?
    var coordinate: CLLocationCoordinate2D
    var banking: Bool?
    var bonus: Bool?
    var contractName: String?
    var bikeStands: Int64?
    var availableBikeStands: Int64?
    var availableBikes: Int64?
    var lastUpdate: Int64?
    var status: String?
    
    init(number:Int64, name:String, address:String, coordinate:CLLocationCoordinate2D, banking:Bool, bonus:Bool, contractName:String, bikeStands:Int64, availableBikeStands:Int64, availableBikes:Int64, lastUpdate:Int64, status:String){
        self.number = number
        self.name = name
        self.address = address
        self.coordinate = coordinate
        self.banking = banking
        self.bonus = bonus
        self.contractName = contractName
        self.bikeStands = bikeStands
        self.availableBikeStands = availableBikeStands
        self.availableBikes = availableBikes
        self.lastUpdate = lastUpdate
        self.status = status
    }
}

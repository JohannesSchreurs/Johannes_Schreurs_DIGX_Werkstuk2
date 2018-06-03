//
//  StationAnnotation.swift
//  Johannes_Schreurs_Werkstuk2
//
//  Created by Johannes Schreurs on 31/05/2018.
//  Copyright © 2018 Johannes Schreurs. All rights reserved.
//

import Foundation
import MapKit
import UIKit


class StationAnnotation: NSObject, MKAnnotation{
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?

    init(coordinate: CLLocationCoordinate2D, title:String, subtitle:String){
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}

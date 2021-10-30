//
//  ViewController.swift
//  WeatherApp
//
//  Created by AW on 10/28/21.
//

import UIKit
import RealmSwift
import Alamofire
import PromiseKit
import SwiftyJSON

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var arr = ["Seattle WA, USA, 50°F", "Shenyang, China, 30°F"]
    var arrCities: [CityInfo] = [CityInfo]()
    var arrWeathers: [CurrentWeather] = [CurrentWeather]()
    @IBOutlet weak var tblView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        loadCities()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrWeathers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = arrCities[indexPath.row].localizedName + String(arrWeathers[indexPath.row].temp) + "°F, " + arrWeathers[indexPath.row].weatherText
        return cell
    }
    
    func loadCities() {
        do {
            let realm = try Realm()
            let cities = realm.objects(CityInfo.self)
            arrCities = Array(cities)
            getAllWeathers(Array(cities)).done { cities in
                self.arrWeathers.append(contentsOf: cities)
                self.tblView.reloadData()
            } .catch {
                error in print(error)
            }
        } catch {
            print("Error reading db")
        }
    }

    func getAllWeathers(_ cities: [CityInfo]) -> Promise<[CurrentWeather]> {
        var promises : [Promise<CurrentWeather>] = []
        for i in 0 ..< cities.count {
            promises.append(getWeather(cities[i].key))
        }
        return when(fulfilled: promises)
    }
    
    func getWeather(_ key : String) -> Promise<CurrentWeather> {
        return Promise<CurrentWeather> { seal -> Void in
            let url = constantss.weatherURL + key + "?apikey=" + constantss.apiKey
            AF.request(url).responseJSON { response in
                if response.error != nil {
                    seal.reject(response.error!)
                }
                let weather = JSON(response.data!).array
                
                guard let firstWeather = weather!.first else {
                    seal.fulfill(CurrentWeather())
                    return
                }
                let localWeather = CurrentWeather()
                localWeather.weatherText = firstWeather["WeatherText"].stringValue
                localWeather.temp = firstWeather["Temperature"]["Imperial"]["Value"].intValue
                seal.fulfill(localWeather)
            }
        }
    }
}


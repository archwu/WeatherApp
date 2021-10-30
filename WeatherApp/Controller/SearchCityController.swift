//
//  SearchCityController.swift
//  WeatherApp
//
//  Created by AW on 10/28/21.
//

import UIKit
import PromiseKit
import SwiftyJSON
import RealmSwift
import Alamofire

class SearchCityViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var arr = ["SEA"]
    var arrCities: [CityInfo] = [CityInfo]()
    
    @IBOutlet weak var tblView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText.count < 3 {
            return
        }
        loadCities(searchText: searchText)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrCities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = arrCities[indexPath.row].localizedName + ", " + arrCities[indexPath.row].administrativeID
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        let city = arrCities[indexPath.row]
        if doesCityExistInDB(city.key) {
            return
        }
        addCityInDB(city)
    }
    
    func loadCities(searchText: String) {
        do {
            arrCities.removeAll()
            getCitiesFromSearch(searchText: searchText).done { cityJSON in
                if cityJSON.count == 0 {
                    return
                }
                for json in cityJSON{
                    let cityInfo = CityInfo()
                    cityInfo.key = json["Key"].stringValue
                    cityInfo.localizedName = json["LocalizedName"].stringValue
                    cityInfo.countryLocalizedName = json["Country"]["LocalizedName"].stringValue
                    cityInfo.type = json["Type"].stringValue
                    cityInfo.administrativeID = json["AdministrativeArea"]["ID"].stringValue
                    self.arrCities.append(cityInfo)
                }
                self.tblView.reloadData()
            } .catch {
                error in print(error)
            }
        } catch {
            print("Error getting cities from API")
        }
    }

    
    func getCitiesFromSearch(searchText: String) -> Promise <[JSON]> {
        return Promise<[JSON]> { seal -> Void in
            let url = constantss.locationSearchURL + "apikey=" + constantss.apiKey + "&q=" + searchText
            let urlString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            AF.request(urlString).responseJSON{ response in
                if (response.error) != nil {
                    seal.reject(response.error!)
                    print(response.error)
                }
                let cities = JSON(response.data!).array
                
                seal.fulfill(cities!)
            }
        }
    }
    
    func doesCityExistInDB (_ key: String) -> Bool {
        do {
            let realm = try Realm()
            if realm.object(ofType: CityInfo.self, forPrimaryKey: key) != nil {
                return true
            }
        } catch {
            print("Error getting data from realm")
        }
        return false
    }
    
    func addCityInDB(_ cityInfo: CityInfo) {
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(cityInfo, update: .modified)
            }
        } catch {
            print("error writing to db \(error)")
        }
    }
    
}

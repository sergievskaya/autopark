//
//  main.swift
//  autopark
//

import Foundation

class Vehicle {
    let make: String
    let model: String
    let year: Int
    let capacity: Int
    var types: [CargoType]?
    var currentLoad: Int = 0
    let fuelTankCapacity: Double
    
    init(make: String, model: String, year: Int, capacity: Int, types: [CargoType]? = nil, fuelTankCapacity: Double) {
        self.make = make
        self.model = model
        self.year = year
        self.capacity = capacity
        self.types = types
        self.fuelTankCapacity = fuelTankCapacity
    }
    
    func loadCargo(cargo: Cargo) -> Bool {
        if let allowedTypes = types, !allowedTypes.contains(cargo.type) {
            print("Ошибка: груз типа \(cargo.type) не поддерживается этим транспортным средством.")
            return false
        }
        
        if currentLoad + cargo.weight > capacity {
            print("Ошибка: превышена грузоподъемность транспортного средства.")
            return false
        }
        
        currentLoad += cargo.weight
        print("\(cargo.description) загружен. Текущая загрузка: \(currentLoad) кг.")
        return true
    }
    
    func unloadCargo() {
        currentLoad = 0
        print("Груз полностью разгружен из транспортного средства '\(make) \(model)'.")
    }
     
    func canGo(path: Int) -> Bool {
        let consumption = 9.0
        let maxDistance = Int((fuelTankCapacity / 2) * consumption)
        return path <= maxDistance
    }
}

class Truck: Vehicle {
    var trailerAttached: Bool
    var trailerCapacity: Int?
    var trailerCurrentLoad: Int = 0
    var trailerTypes: [CargoType]?
    
    init(make: String, model: String, year: Int, capacity: Int, types: [CargoType]? = nil, fuelTankCapacity: Double, trailerAttached: Bool, trailerCapacity: Int? = nil, trailerTypes: [CargoType]? = nil ) {
        self.trailerAttached = trailerAttached
        self.trailerCapacity = trailerCapacity
        self.trailerTypes = trailerTypes
        super.init(make: make, model: model, year: year, capacity: capacity, types: types, fuelTankCapacity: fuelTankCapacity)
    }
    
    override func loadCargo(cargo: Cargo) -> Bool {
        // Загружаем груз в основной отсек
        let truckLoaded = super.loadCargo(cargo: cargo)
        
        // Если груз уже был загружен в основной отсек, возвращаем true
        if truckLoaded {
            return true
        }
        
        // Проверяем, прикреплен ли прицеп и поддерживает ли он данный тип груза
        if trailerAttached, let trailerCapacity = trailerCapacity {
            if trailerCurrentLoad + cargo.weight > trailerCapacity {
                print("Ошибка: груз превышает допустимую грузоподъемность прицепа.")
                return false
            }
            
            // Если тип груза поддерживается прицепом
            if let trailerAllowedCargoTypes = trailerTypes, trailerAllowedCargoTypes.contains(cargo.type) {
                trailerCurrentLoad += cargo.weight // Увеличиваем текущую нагрузку в прицепе
                print("\(cargo.description) загружен в прицеп. Текущая загрузка прицепа: \(trailerCurrentLoad) кг.")
                return true
            } else {
                print("Ошибка: груз типа \(cargo.type.str) не поддерживается прицепом.")
                return false
            }
        }
        
        print("Ошибка: груз не был загружен ни в основной отсек, ни в прицеп.")
        return false
    }
    
    override func unloadCargo() {
        super.unloadCargo()
        trailerCurrentLoad = 0 // Обнуляем груз в прицепе
        print("Груз полностью разгружен из прицепа '\(make) \(model)'.")
    }
}

struct Cargo {
    let description: String
    let weight: Int
    let type: CargoType
    
    init?(description: String, weight: Int, type: CargoType) {
        guard weight >= 0 else {
            print("Ошибка: вес груза не может быть отрицательным.")
            return nil
        }
        self.description = description
        self.weight = weight
        self.type = type
    }
}

enum CargoType: Equatable {
    case fragile(inPackage: Bool) // хрупкий груз
    case perishable(tempRequired: Int) // скоропортящийся груз с температурными требованиями
    case bulk(inContainer: Bool) // сыпучий груз
    
    var str: String {
        switch self {
        case .fragile:
            return "Хрупкий"
        case .perishable(let temp):
            return "Скоропортящиеся (Температура: \(temp)°C)"
        case .bulk:
            return "Сыпучий"
        }
    }
}

class Fleet {
    var vehicles: [Vehicle] = []
    
    func addVehicle(_ vehicle: Vehicle) {
        vehicles.append(vehicle)
    }
    
    func totalCapacity() -> Int {
        return vehicles.reduce(0) { $0 + $1.capacity }
    }
    
    func totalCurrentLoad() -> Int {
        return vehicles.reduce(0) { $0 + $1.currentLoad }
    }
    
    func info() {
        print("В автопарке \(vehicles.count) транспортных средств.")
        print("Общая грузоподъемность: \(totalCapacity()) кг.")
        print("Текущая загрузка: \(totalCurrentLoad()) кг.")
    }
    
    func canGo(cargo: [Cargo], path: Int) -> Bool {
        print("Может ли перевести грузы по маршруту в \(path) км ?")
        
        var loadedVehicles: [Vehicle] = []
        
        // Попытка загрузить каждый груз на подходящий транспорт
        for load in cargo {
            var isCargoLoaded = false
            
            for vehicle in vehicles {
                if vehicle.loadCargo(cargo: load) {
                    loadedVehicles.append(vehicle)
                    isCargoLoaded = true
                    break
                }
            }
            
            if !isCargoLoaded {
                print("Не удалось найти транспортное средство для перевозки '\(load.description)', '\(load.type.str)' груз")
                return false
            }
        }
        
        // Проверка, могут ли транспортные средства проехать заданное расстояние
        for vehicle in loadedVehicles {
            if !vehicle.canGo(path: path) {
                print("'\(vehicle.make) \(vehicle.model)' не может проехать \(path) км маршрута из-за количества топлива")
                return false
            }
        }
        
        return true // Все грузы загружены, и транспортные средства могут проехать
    }
}

// Создаем груз
let fragileCargo = Cargo(description: "Телевизор", weight: 100, type: .fragile(inPackage: true))!
let perishableCargo = Cargo(description: "Молоко", weight: 200, type: .perishable(tempRequired: -10))!

// Создаем транспортные средства
let truck1 = Truck(make: "Volvo", model: "FH16", year: 2020, capacity: 500, fuelTankCapacity: 300, trailerAttached: true, trailerCapacity: 500, trailerTypes: [.fragile(inPackage: true)])
let vehicle1 = Vehicle(make: "Mercedes", model: "Sprinter", year: 2018, capacity: 500, fuelTankCapacity: 100)

// Создаем автопарк
let fleet = Fleet()
fleet.addVehicle(truck1)
fleet.addVehicle(vehicle1)

// Загружаем груз
let loadedFragile = truck1.loadCargo(cargo: fragileCargo)
let loadedPerishable = vehicle1.loadCargo(cargo: perishableCargo)

// Выводим информацию об автопарке
fleet.info()
// Обнуляем груз
truck1.unloadCargo()
vehicle1.unloadCargo()

// Проверяем возможность передвижения
let canTravel = fleet.canGo(cargo: [fragileCargo], path: 100)
print("Может ли проехать маршрут длиной в 100 км? \(canTravel)")


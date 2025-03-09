//
//  MapView.swift
//  TFSMap
//
//  Created by Tyler Wade on 11/13/24.
//

import SwiftUI
import TransformGesture
import simd
import SVGView

class Room {
    public let name: String
    public let position: CGPoint
    
    init(named name: String, at position: CGPoint) {
        
        self.name = name
        self.position = position
    }
}

class Floor {
    
    public let svgNode: SVGNode
    public let level: Int
    public var rooms:[Room] = []
    public var building: Building? = nil
    
    init(svgNode: SVGNode, level: Int) {
        
        self.svgNode = svgNode
        self.level = level
    }
}

class Building {
    
    public let name: String
    public let id: String
    public let roofNode: SVGNode
    public let hitRect: CGRect
    public var floors:[Floor]
    public let defaultFloorIdx: Int
    
    init(
        named name: String, roofNode: SVGNode,
        hitRect: CGRect, floors:[Floor],
        defaultFloor: Int, id: String) {
            
        self.name = name
        self.roofNode = roofNode
        self.hitRect = hitRect
        self.floors = floors
        self.defaultFloorIdx = defaultFloor
        self.id = id
    }
}

struct MapView: View {
    
    // The zoom scale at which the text on the buildings apear
    private static let textAppearScale = 7.0
    
    private static let svgSize: CGSize = CGSize(width: 1000, height: 700)
    
    // This stores the current transform data for the map
    @StateObject private var transform = TouchTransform(
        translation: CGSize(width: 100, height: 190),
        scale: 3,
        scaleRange: 3...30,
        rotationRange: 0...0)
    
    // The size that this view is being drawn at
    @State private var viewSize: CGSize = .zero
    
    // The size of the actaual SVG view that gets rendered
    @State private var svgView: SVGView
    
    @State private var svgDisplayScale: CGFloat = 0
    @State private var svgDisplaySize: CGSize = .zero
    
    // When a building is active, its roof is hidden
    // revealing the interior. Only one building
    // can be active at a time.
    @State private var activeBuilding: Building? = nil
    
    private var buildings:[Building] = []
    
    @State private var selectedFloorIdx: Int = 0
    
    init() {
        
        // Load the SVG view
        let svgURL = Bundle.main.url(forResource: "TandemMap", withExtension: "svg")!
        self.svgView = SVGView(contentsOf: svgURL)
    
        initializeBuildingsAndRooms()
    }
    
    mutating func initializeBuildingsAndRooms() {
        
        // Initialize buildings
        var main = addBuilding(
            named: "Main Building", id: "Main",
            numFloors: 2, defaultFloor: 0)
        var community = addBuilding(
            named: "Community Hall", id: "Community",
            numFloors: 2, defaultFloor: 1)
        var art = addBuilding(
            named: "Arts Annex", id: "Art",
            numFloors: 2, defaultFloor: 0)
        var music = addBuilding(
            named: "Music", id: "Music",
            numFloors: 1, defaultFloor: 0)
        var middle = addBuilding(
            named: "Middle School", id: "Middle",
            numFloors: 2, defaultFloor: 1)
        var math = addBuilding(
            named: "Math/Science", id: "Math",
            numFloors: 2, defaultFloor: 1)
        var pavilion = addBuilding(
            named: "Pavilion", id: "Pavilion",
            numFloors: 1, defaultFloor: 0)
        var gym = addBuilding(
            named: "Field House/Gym", id: "Gym",
            numFloors: 1, defaultFloor: 0)
        
        // Initialize rooms in each building
        
        // Pavilion
        addRoom(pavilion.floors[0], "Storage", "Storage")
        addRoom(pavilion.floors[0], "Restroom", "Rest1")
        addRoom(pavilion.floors[0], "Restroom", "Rest2")
        
        // Community Hall
        addRoom(community.floors[0], "Stairs", "Stairs")
        addRoom(community.floors[0], "Girls Restroom", "FRest")
        addRoom(community.floors[0], "Boys Restroom", "MRest")
        addRoom(community.floors[0], "Office", "Office")
        addRoom(community.floors[0], "Allende", "Allende")
        addRoom(community.floors[0], "Cafe", "Cafe")
        addRoom(community.floors[0], "Hurston", "Hurst")
        addRoom(community.floors[0], "Renaissance", "Ren")
        addRoom(community.floors[0], "Martin", "Martin")
        
        addRoom(community.floors[1], "Community Hall", "Hall")
        addRoom(community.floors[1], "Lobby", "Lobby")
        addRoom(community.floors[1], "Boys Restroom", "MRest")
        addRoom(community.floors[1], "Girls Restroom", "FRest")
        addRoom(community.floors[1], "Costume Closet", "Closet")
        addRoom(community.floors[1], "Backstage", "Backstage")
        
        // Math/Science building
        addRoom(math.floors[0], "Einstein", "Einstein")
        addRoom(math.floors[0], "Restrooms", "Rest")
        addRoom(math.floors[0], "Stairs", "Stairs")
        addRoom(math.floors[0], "Veranda", "Veranda")
        addRoom(math.floors[0], "Avogadro", "Avogadro")
        addRoom(math.floors[0], "Darwin", "Darwin")
        addRoom(math.floors[0], "Storage", "Storage")
        
        addRoom(math.floors[1], "Stairs", "Stairs")
        addRoom(math.floors[1], "Girls Restroom", "FRest")
        addRoom(math.floors[1], "Boys Restroom", "MRest")
        addRoom(math.floors[1], "Gauss", "Gauss")
        addRoom(math.floors[1], "Newton", "Newton")
        addRoom(math.floors[1], "Euler", "Euler")
        addRoom(math.floors[1], "Euclid", "Euclid")
        addRoom(math.floors[1], "Perk", "Perk")
        addRoom(math.floors[1], "Library", "Library")
        
        // Gym
        addRoom(gym.floors[0], "Office", "Office")
        addRoom(gym.floors[0], "Visitor", "Visitor")
        addRoom(gym.floors[0], "Gym", "Gym")
        addRoom(gym.floors[0], "Weight Room", "Weight")
        addRoom(gym.floors[0], "Girls Locker Room", "FLocker")
        addRoom(gym.floors[0], "Boys Locker Room", "MLocker")
        
        // Music building
        addRoom(music.floors[0], "US Music", "US")
        addRoom(music.floors[0], "MS Music", "MS")
        
        // Main building
        addRoom(main.floors[0], "Admissions Office", "Admissions")
        addRoom(main.floors[0], "Lobby", "Lobby")
        addRoom(main.floors[0], "Faculty Lounge", "TeacherLounge")
        addRoom(main.floors[0], "Stairs", "Stairs")
        addRoom(main.floors[0], "Restroom", "Rest")
        addRoom(main.floors[0], "Senior Lounge", "SeniorLounge")
        addRoom(main.floors[0], "Alling", "Alling")
        addRoom(main.floors[0], "Blue Room", "Blue")
        
        addRoom(main.floors[1], "Head of School Office", "Head")
        addRoom(main.floors[1], "Assistant Office", "Admin")
        addRoom(main.floors[1], "Office", "Office")
        addRoom(main.floors[1], "LRC", "LRC")
        addRoom(main.floors[1], "College Counseling Office", "College")
        
        // Middle school building
        addRoom(middle.floors[0], "Restroom", "Rest")
        addRoom(middle.floors[0], "Porter", "Porter")
        addRoom(middle.floors[0], "Meyer", "Meyer")
        
        addRoom(middle.floors[1], "Summers", "Summers")
        addRoom(middle.floors[1], "Macdonald", "Mac")
        addRoom(middle.floors[1], "Henrikson", "Henrikson")
        addRoom(middle.floors[1], "Carson", "Carson")
        
        // Art building
        addRoom(art.floors[0], "Art Room", "Art")
        addRoom(art.floors[0], "Ceramics", "Ceramics")
        addRoom(art.floors[0], "Office", "Office")
        addRoom(art.floors[0], "US Counseling Office", "ConUS")
        addRoom(art.floors[0], "Makerspace", "Makerspace")
        
        addRoom(art.floors[1], "MS Counseling Office", "ConMS")
    }
    
    mutating func addRoom(_ floor: Floor, _ name: String, _ id: String) {
        // For some reason the compiler cannot type check
        // this expression in reasonable time?????
        //let roomId = floor.building!.id + "_F" + String(floor.level) + "_" + id
        
        let part1 = floor.building!.id + "_F"
        let part2 = String(floor.level) + "_" + id
        let roomId = part1 + part2
        
        let node = getNode(named: roomId) as! SVGCircle
        node.opacity = 0
        floor.rooms.append(Room(named: name, at: CGPoint(x: node.cx, y: node.cy)))
    }
    
    mutating func addBuilding(
        named name: String, id: String,
        numFloors: Int, defaultFloor: Int) -> Building {
        
        let hitBoxNode = getNode(named: id + "_HitBox")
        let hitRect = svgRectToCGRect(hitBoxNode as! SVGRect)
        
        var floors:[Floor] = []
        
        for index in 1...numFloors {
            let floorNode = getNode(named: id + "_F" + String(index))
            floorNode.opacity = 0
            floors.append(Floor(svgNode: floorNode, level: index))
        }
        
        let building = Building(
            named: name,
            roofNode: getNode(named: id + "_Roof"),
            hitRect: hitRect,
            floors: floors,
            defaultFloor: defaultFloor,
            id: id)
            
        for index in 0..<numFloors {
            building.floors[index].building = building
        }
        
        buildings.append(building)
        hitBoxNode.opacity = 0
        return building
    }
    
    func getNode(named name: String) -> SVGNode {
        return svgView.getNode(byId: name)!
    }
    
    func getRect(named name: String) -> CGRect {
        return svgRectToCGRect(getNode(named: name) as! SVGRect)
    }
    
    func svgRectToCGRect(_ svgRect: SVGRect) -> CGRect {
        return CGRect(
            x: svgRect.x,
            y: svgRect.y,
            width: svgRect.width,
            height: svgRect.height)
    }
    
    // Transforms a point from screen space to map space
    func ScreenToMapSpace(_ point: CGPoint) -> CGPoint {
        var trPoint = transform
            .matrixInveresed
            .transformed2D(point.simd_float2)
        
        let size = svgDisplaySize
        let scale = svgDisplayScale
        
        return CGPoint(
            x: (CGFloat(trPoint.x) + size.width / 2) / scale,
            y: (CGFloat(trPoint.y) + size.height / 2) / scale)
    }
    
    // Transforms a point from map space to screen space
    func MapToScreenSpace(_ mapPoint: CGPoint) -> CGPoint {
        
        let size = svgDisplaySize
        let scale = svgDisplayScale
        
        let aPoint = CGPoint(x: mapPoint.x * scale - size.width / 2, y: mapPoint.y * scale - size.height / 2)
        
        let trPoint = transform
            .matrix
            .transformed2D(aPoint.simd_float2)
        
        return CGPoint(
            x: CGFloat(trPoint.x),
            y: CGFloat(trPoint.y))
    }
    
    // Gets the building whose hitRect contains mapPoint
    private func getBuilding(at mapPoint: CGPoint) -> Building? {
        for building in buildings {
            if building.hitRect.contains(mapPoint) {
                return building
            }
        }
        return nil
    }
    
    // Called whenever the user taps on the map
    func onTapped(screenPoint: CGPoint) {
        
        // Find the point on the map that the user tapped on
        var mapPoint = ScreenToMapSpace(screenPoint)
        
        // Check if this point is conateined within a building
        let tappedBuilding = getBuilding(at: mapPoint)
        
        // Only do something if the building that was tapped
        // is not the same one that is already active
        if activeBuilding !== tappedBuilding {
            
            // Show the roof of the building that was previously active
            if activeBuilding !== nil {
                activeBuilding!.roofNode.opacity = 1
                activeBuilding!.floors[selectedFloorIdx].svgNode.opacity = 0
            }
            
            activeBuilding = tappedBuilding
            
            // Hide the roof that is now currently active
            if tappedBuilding !== nil {
                tappedBuilding!.roofNode.opacity = 0
                tappedBuilding!.floors[tappedBuilding!.defaultFloorIdx].svgNode.opacity = 1
            }
            
            if activeBuilding !== nil {
                selectedFloorIdx = activeBuilding!.defaultFloorIdx
            }
        }
        else if activeBuilding !== nil && activeBuilding!.floors.count > 1 {
            if selectedFloorIdx + 1 >= activeBuilding!.floors.count {
                setFloor(index: 0)
            } else {
                setFloor(index: selectedFloorIdx + 1)
            }
        }
        
    }
    
    func setFloor(index: Int) {
        activeBuilding!.floors[selectedFloorIdx].svgNode.opacity = 0
        selectedFloorIdx = index
        activeBuilding!.floors[index].svgNode.opacity = 1
    }
    
    func computeTextOpacity() -> CGFloat {
        return 1.0
//        return transform.scale >= Self.textAppearScale ? 1.0 : 0.0
    }
    
    func drawText(_ context: inout GraphicsContext, _ string: String, _ point: CGPoint) {
        var textPos = CGPoint(x: point.x, y: point.y)
        
        let font = Font.system(size: 16)
        
        let textOpacity = computeTextOpacity()
        
        let shadowText = Text(string)
            .font(font)
            .foregroundStyle(Color(hue: 0, saturation: 0, brightness: 0.3).opacity(textOpacity))
        let shadowTextPos = CGPoint(x: point.x + 1, y: point.y + 1)
        context.draw(context.resolve(shadowText), at: shadowTextPos, anchor: .center)
        
        let text = Text(string)
            .font(font)
            .foregroundStyle(.white.opacity(textOpacity))
        context.draw(context.resolve(text), at: point, anchor: .center)
    }
    
    var popupContent: some View {
        HStack {
            Text(activeBuilding?.name ?? "")
                .font(.system(size: 20, weight: .bold))
            
            Spacer()
            
            Text("Floor " + String(selectedFloorIdx + 1))
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    var popupFrame: some View {
        VStack {
            RoundedRectangle(cornerSize: CGSize(width: 15, height: 15))
                .fill(Color.white)
                .frame(width: 300, height: 50)
                .overlay {
                    popupContent
                }
            
            Spacer()
        }
        .padding()
    }
    
    var body: some View {
        ZStack {
            Color("MapBackground", bundle: Bundle.main)
                .ignoresSafeArea()
            
            ZStack {
                
                // This is the actual SVG that is being rendered
                svgView
                    .transformEffect(transform)
                    .background(GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                DispatchQueue.main.async {
                                    viewSize = geometry.size
                                    //geometry.safeAreaRegions
                                    
                                    // Calculate the size at which the SVG is being rendered at
                                    // without any transformations applied (pan/zoom)
                                    svgDisplayScale = viewSize.width / Self.svgSize.width
                                    svgDisplaySize = CGSize(
                                        width: Self.svgSize.width * svgDisplayScale,
                                        height: Self.svgSize.height * svgDisplayScale)
                                }
                            }
                    })

                // Draw the names of the buildings ontop with a canvas
                Canvas { context, _ in
                    
                    for building in buildings {
                        
                        if building === activeBuilding {
                            continue
                        }
                        
                        let mapPoint = CGPoint(
                            x: building.hitRect.midX,
                            y: building.hitRect.midY)
                        
                        let screenPoint = MapToScreenSpace(mapPoint)
                        
                        drawText(&context, building.name, screenPoint)
                    }
                    
                    if activeBuilding !== nil {
                        let floor = activeBuilding!.floors[selectedFloorIdx]
                        for room in floor.rooms {
                            let screenPoint = MapToScreenSpace(room.position)
                            drawText(&context, room.name, screenPoint)
                        }
                    }
                }
            }
            
            if activeBuilding !== nil {
                popupFrame
            }
        }
        .transformGesture(transform: transform, draggingDisabled: true, onTap: onTapped)
    }
}

//#Preview {
//    MapView()
//}

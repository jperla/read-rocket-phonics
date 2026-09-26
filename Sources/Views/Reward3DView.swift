import SwiftUI
import SceneKit
import UIKit

/// Which 3D celebration scene to show.
enum RewardScene: String, CaseIterable { case star, gem, balloons, fireworks, treasure }

/// Genuine 3D rewards rendered with SceneKit. A small cast keeps celebrations
/// fresh: a glossy gold star, a spinning jewel, and a floating balloon bunch
/// (the milestone "party"). Skipped under UI testing — the continuous render
/// loop would keep XCUITest from ever reaching "idle".
struct Reward3DView: UIViewRepresentable {
    var scene: RewardScene = .star

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.scene = Reward3DView.build(scene)
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.rendersContinuously = true
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    // MARK: scene assembly

    private static func build(_ kind: RewardScene) -> SCNScene {
        let scene = SCNScene()
        addLights(scene)
        let cam = SCNNode()
        cam.camera = SCNCamera()
        cam.position = SCNVector3(0, 0, cameraZ(kind))
        scene.rootNode.addChildNode(cam)
        switch kind {
        case .star:      addStar(scene)
        case .gem:       addGem(scene)
        case .balloons:  addBalloons(scene)
        case .fireworks: addFireworks(scene)
        case .treasure:  addTreasure(scene)
        }
        return scene
    }

    private static func addLights(_ scene: SCNScene) {
        let key = SCNNode(); key.light = SCNLight(); key.light!.type = .omni
        key.light!.intensity = 1400; key.position = SCNVector3(4, 6, 9)
        scene.rootNode.addChildNode(key)
        let rim = SCNNode(); rim.light = SCNLight(); rim.light!.type = .omni
        rim.light!.intensity = 700; rim.light!.color = UIColor(red: 1, green: 0.7, blue: 0.4, alpha: 1)
        rim.position = SCNVector3(-5, -3, 5)
        scene.rootNode.addChildNode(rim)
        let amb = SCNNode(); amb.light = SCNLight(); amb.light!.type = .ambient
        amb.light!.intensity = 500
        scene.rootNode.addChildNode(amb)
    }

    private static func popIn(_ node: SCNNode, to: CGFloat) {
        node.scale = SCNVector3(0.01, 0.01, 0.01)
        let pop = SCNAction.scale(to: to * 1.18, duration: 0.45); pop.timingMode = .easeOut
        let settle = SCNAction.scale(to: to, duration: 0.22); settle.timingMode = .easeInEaseOut
        node.runAction(.sequence([pop, settle]))
    }

    private static func bob(_ node: SCNNode, _ dy: CGFloat = 0.22) {
        let up = SCNAction.moveBy(x: 0, y: dy, z: 0, duration: 1.1); up.timingMode = .easeInEaseOut
        node.runAction(.repeatForever(.sequence([up, up.reversed()])))
    }

    // MARK: star

    private static func addStar(_ scene: SCNScene) {
        let tilt = SCNNode()
        tilt.eulerAngles = SCNVector3(0.4, -0.2, 0)
        scene.rootNode.addChildNode(tilt)
        let star = SCNNode(geometry: starGeometry())
        tilt.addChildNode(star)
        popIn(star, to: 1.6)
        star.runAction(.repeatForever(.rotateBy(x: 0, y: 0, z: .pi * 2, duration: 3.4)))
        bob(tilt)
    }

    private static func starGeometry() -> SCNGeometry {
        let path = UIBezierPath()
        for i in 0..<10 {
            let r: CGFloat = (i % 2 == 0) ? 1.0 : 0.46
            let a = CGFloat(i) / 10 * 2 * .pi - .pi / 2
            let p = CGPoint(x: cos(a) * r, y: sin(a) * r)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.close()
        let shape = SCNShape(path: path, extrusionDepth: 0.4)
        shape.chamferRadius = 0.08
        let gold = SCNMaterial()
        gold.lightingModel = .physicallyBased
        gold.diffuse.contents = UIColor(red: 1.0, green: 0.82, blue: 0.22, alpha: 1)
        gold.metalness.contents = 0.9
        gold.roughness.contents = 0.18
        shape.materials = [gold]
        return shape
    }

    // MARK: gem

    private static func addGem(_ scene: SCNScene) {
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = UIColor(red: 1.0, green: 0.31, blue: 0.55, alpha: 1)  // jewel pink
        mat.metalness.contents = 0.35
        mat.roughness.contents = 0.08

        let gem = SCNNode()
        let top = SCNNode(geometry: SCNPyramid(width: 1.05, height: 0.75, length: 1.05))
        top.geometry!.materials = [mat]
        gem.addChildNode(top)
        let bot = SCNNode(geometry: SCNPyramid(width: 1.05, height: 0.6, length: 1.05))
        bot.geometry!.materials = [mat]
        bot.eulerAngles = SCNVector3(Float.pi, 0, 0)   // flip so the two bases meet
        gem.addChildNode(bot)

        gem.eulerAngles = SCNVector3(0.18, 0, 0)
        scene.rootNode.addChildNode(gem)
        popIn(gem, to: 1.35)
        gem.runAction(.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 3.0)))
        bob(gem, 0.18)
    }

    // MARK: balloons (milestone party)

    private static func addBalloons(_ scene: SCNScene) {
        let cluster = SCNNode()
        let cols: [UIColor] = [
            UIColor(red: 1, green: 0.42, blue: 0.55, alpha: 1),
            UIColor(red: 0.40, green: 0.78, blue: 1, alpha: 1),
            UIColor(red: 0.45, green: 0.85, blue: 0.45, alpha: 1),
            UIColor(red: 1, green: 0.82, blue: 0.25, alpha: 1),
            UIColor(red: 0.66, green: 0.55, blue: 0.98, alpha: 1)
        ]
        let pos: [(Float, Float)] = [(-1.1, 0.1), (-0.45, 0.6), (0.45, 0.55), (1.1, 0.05), (0.0, -0.05)]
        for i in 0..<5 {
            let b = balloon(cols[i])
            b.position = SCNVector3(pos[i].0, pos[i].1, Float(i) * 0.06)
            let up = SCNAction.moveBy(x: 0, y: 0.16, z: 0, duration: 0.9 + Double(i) * 0.13)
            up.timingMode = .easeInEaseOut
            b.runAction(.repeatForever(.sequence([up, up.reversed()])))
            cluster.addChildNode(b)
        }
        popIn(cluster, to: 1.0)
        let sway = SCNAction.rotateBy(x: 0, y: 0, z: 0.06, duration: 1.6); sway.timingMode = .easeInEaseOut
        cluster.runAction(.repeatForever(.sequence([sway, sway.reversed()])))
        scene.rootNode.addChildNode(cluster)
    }

    private static func balloon(_ color: UIColor) -> SCNNode {
        let n = SCNNode()
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.diffuse.contents = color
        m.roughness.contents = 0.35
        let body = SCNSphere(radius: 0.4); body.materials = [m]
        let bn = SCNNode(geometry: body); bn.scale = SCNVector3(1, 1.2, 1)
        n.addChildNode(bn)
        let knot = SCNSphere(radius: 0.06); knot.materials = [m]
        let kn = SCNNode(geometry: knot); kn.position = SCNVector3(0, -0.5, 0)
        n.addChildNode(kn)
        let str = SCNCylinder(radius: 0.012, height: 0.62)
        let sm = SCNMaterial(); sm.diffuse.contents = UIColor(white: 0.35, alpha: 1); str.materials = [sm]
        let sn = SCNNode(geometry: str); sn.position = SCNVector3(0, -0.85, 0)
        n.addChildNode(sn)
        return n
    }

    // MARK: fireworks + treasure

    private static func cameraZ(_ k: RewardScene) -> Float {
        switch k {
        case .balloons:  return 5.4
        case .fireworks: return 7.0
        case .treasure:  return 4.8
        default:         return 4.3
        }
    }

    private static func goldMaterial() -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.diffuse.contents = UIColor(red: 1.0, green: 0.82, blue: 0.22, alpha: 1)
        m.metalness.contents = 0.9
        m.roughness.contents = 0.2
        return m
    }

    private static func sparkImage() -> UIImage {
        let s = CGSize(width: 48, height: 48)
        return UIGraphicsImageRenderer(size: s).image { ctx in
            let cg = ctx.cgContext
            let cols = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
            let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cols, locations: [0, 1])!
            cg.drawRadialGradient(g, startCenter: CGPoint(x: 24, y: 24), startRadius: 0,
                                  endCenter: CGPoint(x: 24, y: 24), endRadius: 24, options: [])
        }
    }

    private static func addFireworks(_ scene: SCNScene) {
        let colors: [UIColor] = [.systemPink, .systemTeal, .systemYellow, .systemPurple, .systemGreen]
        let spots: [(Float, Float)] = [(-1.6, 0.8), (1.6, 1.2), (0, -0.3), (-1.0, -1.1), (1.2, -0.7)]
        let img = sparkImage()
        for i in 0..<5 {
            let ps = SCNParticleSystem()
            ps.particleImage = img
            ps.birthRate = 700
            ps.emissionDuration = 0.22
            ps.idleDuration = 0.8
            ps.idleDurationVariation = 0.7
            ps.loops = true
            ps.particleLifeSpan = 1.4
            ps.particleLifeSpanVariation = 0.5
            ps.emitterShape = SCNSphere(radius: 0.04)
            ps.birthDirection = .random
            ps.spreadingAngle = 180
            ps.particleVelocity = 3.6
            ps.particleVelocityVariation = 1.6
            ps.acceleration = SCNVector3(0, -2.6, 0)
            ps.particleColor = colors[i]
            ps.particleColorVariation = SCNVector4(0.12, 0.2, 0.2, 0)
            ps.particleSize = 0.13
            ps.particleSizeVariation = 0.05
            ps.blendMode = .additive
            ps.isLightingEnabled = false
            let node = SCNNode()
            node.position = SCNVector3(spots[i].0, spots[i].1, 0)
            node.addParticleSystem(ps)
            scene.rootNode.addChildNode(node)
        }
    }

    private static func addTreasure(_ scene: SCNScene) {
        let chest = SCNNode()
        chest.eulerAngles = SCNVector3(0.12, -0.5, 0)   // 3/4 view

        let wood = SCNMaterial()
        wood.lightingModel = .physicallyBased
        wood.diffuse.contents = UIColor(red: 0.40, green: 0.26, blue: 0.13, alpha: 1)
        wood.roughness.contents = 0.6

        let base = SCNNode(geometry: SCNBox(width: 2.0, height: 1.1, length: 1.3, chamferRadius: 0.08))
        base.geometry!.materials = [wood]
        base.position = SCNVector3(0, -0.25, 0)
        chest.addChildNode(base)

        let goldFill = SCNNode(geometry: SCNBox(width: 1.7, height: 0.5, length: 1.0, chamferRadius: 0.06))
        let gmat = goldMaterial()
        gmat.emission.contents = UIColor(red: 0.5, green: 0.38, blue: 0.05, alpha: 1)
        goldFill.geometry!.materials = [gmat]
        goldFill.position = SCNVector3(0, 0.45, 0)
        chest.addChildNode(goldFill)

        for (i, p) in [(-0.5, 0.25), (0.05, 0.32), (0.5, 0.2)].enumerated() {
            let coin = SCNNode(geometry: SCNCylinder(radius: 0.22, height: 0.06))
            coin.geometry!.materials = [goldMaterial()]
            coin.position = SCNVector3(Float(p.0), 0.62 + Float(i) * 0.03, Float(p.1))
            coin.eulerAngles = SCNVector3(0.25, 0, 0)
            chest.addChildNode(coin)
        }

        // metal clasp on the front face
        let metal = SCNMaterial()
        metal.lightingModel = .physicallyBased
        metal.diffuse.contents = UIColor(white: 0.32, alpha: 1)
        metal.metalness.contents = 0.7
        metal.roughness.contents = 0.4
        let clasp = SCNNode(geometry: SCNBox(width: 0.34, height: 0.5, length: 0.12, chamferRadius: 0.03))
        clasp.geometry!.materials = [metal]
        clasp.position = SCNVector3(0, -0.12, 0.66)
        chest.addChildNode(clasp)

        let hinge = SCNNode()
        hinge.position = SCNVector3(0, 0.32, -0.65)
        let lid = SCNNode(geometry: SCNBox(width: 2.05, height: 0.45, length: 1.4, chamferRadius: 0.08))
        lid.geometry!.materials = [wood]
        lid.position = SCNVector3(0, 0.12, 0.65)   // closed: rests on top
        hinge.addChildNode(lid)
        chest.addChildNode(hinge)
        let open = SCNAction.rotateBy(x: -1.25, y: 0, z: 0, duration: 0.55); open.timingMode = .easeOut
        hinge.runAction(.sequence([.wait(duration: 0.35), open]))

        popIn(chest, to: 1.2)
        bob(chest, 0.12)
        scene.rootNode.addChildNode(chest)
    }
}

import SwiftUI
import SceneKit
import UIKit

/// Ambient 3D space backdrop for the Mentava-style slice: a slowly turning
/// ringed planet, a friendly rocket bobbing in orbit, and a drifting starfield.
/// When `blastToken` increments the rocket blasts off and a fresh planet rolls
/// in — the "you reached the next world" mastery payoff.
///
/// Skipped under UI testing — the continuous render loop never goes idle, which
/// would hang XCUITest forever.
struct SliceSceneView: UIViewRepresentable {
    var blastToken: Int = 0
    var theme: Theme = .default

    /// Each curriculum unit gets its own world: a planet + accent colour.
    struct Theme: Equatable {
        var planet: UIColor
        var accent: UIColor
        static let `default` = Theme(planet: UIColor(red: 0.42, green: 0.78, blue: 1.0, alpha: 1),
                                     accent: UIColor(red: 1.0, green: 0.82, blue: 0.42, alpha: 1))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling2X
        view.rendersContinuously = true
        view.isUserInteractionEnabled = false
        let scene = SCNScene()
        context.coordinator.theme = theme
        context.coordinator.build(in: scene)
        view.scene = scene
        context.coordinator.lastToken = blastToken
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if blastToken != context.coordinator.lastToken {
            context.coordinator.lastToken = blastToken
            context.coordinator.blastOff()
        }
    }

    // MARK: - Scene assembly

    final class Coordinator {
        weak var scene: SCNScene?
        var rocket: SCNNode?
        var planet: SCNNode?
        var lastToken = 0
        var theme = SliceSceneView.Theme.default

        func build(in scene: SCNScene) {
            self.scene = scene

            let cam = SCNNode()
            cam.camera = SCNCamera()
            cam.camera!.fieldOfView = 60
            cam.position = SCNVector3(0, 0, 9)
            scene.rootNode.addChildNode(cam)

            let key = SCNNode()
            key.light = SCNLight(); key.light!.type = .omni
            key.light!.intensity = 1200
            key.position = SCNVector3(5, 7, 9)
            scene.rootNode.addChildNode(key)

            let amb = SCNNode()
            amb.light = SCNLight(); amb.light!.type = .ambient
            amb.light!.intensity = 480
            amb.light!.color = UIColor(red: 0.62, green: 0.70, blue: 1.0, alpha: 1)
            scene.rootNode.addChildNode(amb)

            addStars(scene)

            let p = makePlanet()
            p.position = SCNVector3(2.5, -2.7, -1)
            p.runAction(.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 28)))
            scene.rootNode.addChildNode(p)
            planet = p

            let r = makeRocket()
            r.position = SCNVector3(-2.7, -0.3, 1.6)
            r.eulerAngles = SCNVector3(0, 0, 0.12)
            scene.rootNode.addChildNode(r)
            rocket = r
            startIdle(r)
        }

        private func startIdle(_ r: SCNNode) {
            let up = SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 1.6)
            up.timingMode = .easeInEaseOut
            r.runAction(.repeatForever(.sequence([up, up.reversed()])), forKey: "bob")
            let sway = SCNAction.rotateBy(x: 0, y: 0, z: 0.07, duration: 2.1)
            sway.timingMode = .easeInEaseOut
            r.runAction(.repeatForever(.sequence([sway, sway.reversed()])), forKey: "sway")
        }

        private func addStars(_ scene: SCNScene) {
            let ps = SCNParticleSystem()
            ps.birthRate = 50
            ps.particleLifeSpan = 7
            ps.particleSize = 0.035
            ps.particleSizeVariation = 0.05
            ps.emitterShape = SCNBox(width: 20, height: 13, length: 1, chamferRadius: 0)
            ps.particleColor = .white
            ps.particleColorVariation = SCNVector4(0.1, 0.1, 0.25, 0)
            ps.birthDirection = .constant
            ps.emittingDirection = SCNVector3(0, 0, 1)
            ps.particleVelocity = 0.18
            ps.particleVelocityVariation = 0.1
            ps.blendMode = .additive
            ps.isLightingEnabled = false
            let node = SCNNode()
            node.position = SCNVector3(0, 0, -5)
            node.addParticleSystem(ps)
            scene.rootNode.addChildNode(node)
        }

        private func makePlanet() -> SCNNode {
            let m = SCNMaterial()
            m.lightingModel = .physicallyBased
            m.diffuse.contents = theme.planet
            m.roughness.contents = 0.55
            let sphere = SCNSphere(radius: 1.7)
            sphere.materials = [m]
            let n = SCNNode(geometry: sphere)

            let rm = SCNMaterial()
            rm.diffuse.contents = theme.accent.withAlphaComponent(0.9)
            rm.lightingModel = .constant
            rm.isDoubleSided = true
            let ring = SCNTorus(ringRadius: 2.5, pipeRadius: 0.07)
            ring.materials = [rm]
            let rn = SCNNode(geometry: ring)
            rn.eulerAngles = SCNVector3(0.5, 0, 0.25)
            n.addChildNode(rn)
            return n
        }

        private func makeRocket() -> SCNNode {
            let rocket = SCNNode()

            let bodyM = SCNMaterial()
            bodyM.lightingModel = .physicallyBased
            bodyM.diffuse.contents = UIColor.white
            bodyM.roughness.contents = 0.35
            let body = SCNCylinder(radius: 0.34, height: 1.3)
            body.materials = [bodyM]
            rocket.addChildNode(SCNNode(geometry: body))

            let accentM = SCNMaterial()
            accentM.lightingModel = .physicallyBased
            accentM.diffuse.contents = theme.accent
            accentM.roughness.contents = 0.3

            let nose = SCNCone(topRadius: 0, bottomRadius: 0.34, height: 0.55)
            nose.materials = [accentM]
            let nn = SCNNode(geometry: nose)
            nn.position = SCNVector3(0, 0.92, 0)
            rocket.addChildNode(nn)

            let winM = SCNMaterial()
            winM.lightingModel = .physicallyBased
            winM.diffuse.contents = UIColor(red: 0.5, green: 0.86, blue: 1.0, alpha: 1)
            winM.metalness.contents = 0.3
            winM.roughness.contents = 0.1
            let win = SCNSphere(radius: 0.16)
            win.materials = [winM]
            let wn = SCNNode(geometry: win)
            wn.position = SCNVector3(0, 0.18, 0.3)
            rocket.addChildNode(wn)

            for a in [Float(0), Float.pi * 2 / 3, Float.pi * 4 / 3] {
                let fin = SCNPyramid(width: 0.32, height: 0.46, length: 0.16)
                fin.materials = [accentM]
                let fnode = SCNNode(geometry: fin)
                fnode.position = SCNVector3(sin(a) * 0.32, -0.78, cos(a) * 0.32)
                fnode.eulerAngles = SCNVector3(.pi, -a, 0)   // apex points down
                rocket.addChildNode(fnode)
            }

            let ex = SCNParticleSystem()
            ex.birthRate = 240
            ex.particleLifeSpan = 0.5
            ex.particleSize = 0.13
            ex.particleSizeVariation = 0.06
            ex.emitterShape = SCNSphere(radius: 0.08)
            ex.particleColor = UIColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1)
            ex.particleColorVariation = SCNVector4(0.08, 0.2, 0.1, 0)
            ex.emittingDirection = SCNVector3(0, -1, 0)
            ex.spreadingAngle = 16
            ex.particleVelocity = 1.7
            ex.acceleration = SCNVector3(0, -1, 0)
            ex.blendMode = .additive
            ex.isLightingEnabled = false
            let exNode = SCNNode()
            exNode.position = SCNVector3(0, -0.72, 0)
            exNode.addParticleSystem(ex)
            rocket.addChildNode(exNode)

            rocket.scale = SCNVector3(0.85, 0.85, 0.85)
            return rocket
        }

        // MARK: - Blast-off payoff

        func blastOff() {
            guard let r = rocket else { return }
            r.removeAllActions()
            let up = SCNAction.moveBy(x: 0.6, y: 12, z: -2, duration: 1.05)
            up.timingMode = .easeIn
            let shrink = SCNAction.scale(to: 0.08, duration: 1.05)
            r.runAction(.group([up, shrink])) { [weak self] in
                guard let self else { return }
                // bring a fresh rocket back up from below for the next world
                r.position = SCNVector3(-2.7, -9, 1.6)
                r.scale = SCNVector3(0.85, 0.85, 0.85)
                let back = SCNAction.move(to: SCNVector3(-2.7, -0.3, 1.6), duration: 0.95)
                back.timingMode = .easeOut
                r.runAction(back) { [weak self] in self?.startIdle(r) }
            }
        }

    }
}

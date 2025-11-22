//
//  PortalWindowView.swift
//  VisionOSTC
//
//  Created by Yugo Sugiyama on 2025/11/16.
//

import SwiftUI
import RealityKit

struct PortalWindowView: View {
    @Environment(AppModel.self) var appModel

    // Portalエンティティへの参照
    @State private var portalEntity: Entity?

    // 現在のPortalサイズ（Windowサイズに基づく）
    @State private var currentPortalSize: Float = 0.5

    var body: some View {
        GeometryReader { geometry in
            RealityView { content in
                // Portalを作成して追加
                let portal = createPortalEntity(size: currentPortalSize)
                content.add(portal)
                portalEntity = portal

                print("PortalWindowView: Portal作成完了")
            } update: { content in
                // Portalのサイズを更新
                if let portal = portalEntity {
                    updatePortalSize(portal: portal, size: currentPortalSize)
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                // Windowサイズに基づいてPortalサイズを計算
                // 小さい方の辺に合わせ、少しマージンを取る
                let minDimension = min(newSize.width, newSize.height)
                // ポイントからメートルに変換（およそ1000ポイント = 1メートル）
                // マージンを確保するため90%のサイズにする
                let newPortalSize = Float(minDimension) / 1000.0 * 0.9
                currentPortalSize = max(0.1, newPortalSize)
                print("Window size changed: \(newSize), Portal size: \(currentPortalSize)")
            }
            .onAppear {
                // 初期サイズを設定
                let minDimension = min(geometry.size.width, geometry.size.height)
                currentPortalSize = Float(minDimension) / 1000.0 * 0.9
            }
        }
    }

    /// Portalのサイズを更新
    private func updatePortalSize(portal: Entity, size: Float) {
        // Portal平面のサイズを更新
        if let portalPlane = portal.findEntity(named: "portalPlane") as? ModelEntity {
            let newMesh = MeshResource.generatePlane(width: size, height: size)
            portalPlane.model?.mesh = newMesh
        }

        // 空間写真（ImagePresentationComponent）側のスケールを更新
        if let portalWorld = portal.findEntity(named: "portalWorld"),
           let spatialPhoto = portalWorld.findEntity(named: "spatialPhoto") {
            let scaleFactor: Float = 1.0 // 必要に応じて調整
            spatialPhoto.scale = [size * scaleFactor, size * scaleFactor, 1]
        }
    }

    /// Portalエンティティを作成
    private func createPortalEntity(size: Float) -> Entity {
        let portalRoot = Entity()
        portalRoot.name = "portalRoot"

        // Portal内部の世界を作成
        let portalWorld = Entity()
        portalWorld.name = "portalWorld"
        portalWorld.components.set(WorldComponent())

        // 写真を読み込む
        Task {
            do {
                try await createPhotoEnvironment(on: portalWorld, size: size)
                print("空間写真の読み込み成功")
            } catch {
                print("環境の読み込み失敗: \(error.localizedDescription)")
            }
        }

        portalRoot.addChild(portalWorld)

        // Portal入口を作成
        // generatePlane(width:, height:)はXY平面（正面向き）を生成
        let portalMesh = MeshResource.generatePlane(
            width: size,
            height: size
        )

        let portalMaterial = PortalMaterial()
        let portalPlane = ModelEntity(mesh: portalMesh, materials: [portalMaterial])
        portalPlane.name = "portalPlane"
        portalPlane.components.set(PortalComponent(target: portalWorld))

        // 回転なし（XY平面はそのまま正面を向く）

        portalRoot.addChild(portalPlane)

        print("Portal作成完了: サイズ=\(size)")

        return portalRoot
    }

    /// 写真環境を作成
    private func createPhotoEnvironment(on root: Entity, size: Float) async throws {
        guard let imageURL = Bundle.main.url(forResource: "space_picture", withExtension: "heic") else {
            throw NSError(domain: "PortalError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load space_picture.heic"])
        }

        // 空間写真を表示するためのエンティティを作成
        let imageEntity = Entity()
        imageEntity.name = "spatialPhoto"

        // ImagePresentationComponent を構成（async/throws）
        var presentationComponent = try await ImagePresentationComponent(contentsOf: imageURL)
        presentationComponent.desiredViewingMode = .spatial3DImmersive
        imageEntity.components.set(presentationComponent)

        // Portal平面と同様に、XY平面正面を向ける（PortalWindowView は回転なしのためそのまま）
        // 40cm奥に配置（Z軸の負方向）
        imageEntity.position = [0, 0, -0.4]

        // Portalサイズに合わせてスケールを調整
        let scaleFactor: Float = 1.0 / 0.3 // 必要に応じて調整
        imageEntity.scale = [size * scaleFactor, size * scaleFactor, 1]

        root.addChild(imageEntity)
    }
}

#Preview(windowStyle: .plain) {
    PortalWindowView()
        .environment(AppModel())
}

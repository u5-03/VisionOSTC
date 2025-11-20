//
//  ImmersiveView.swift
//  VisionOSTC
//
//  Created by Yugo Sugiyama on 2025/11/16.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(AppModel.self) var appModel

    // RealityKitのコンテンツを保持するためのルートエンティティ
    @State private var rootEntity = Entity()

    // Portalエンティティへの参照
    @State private var portalEntity: Entity?

    // Portalが表示されているかどうか
    @State private var isPortalVisible = false

    // Portal設定（AppModelから取得）
    private var portalPosition: SIMD3<Float> {
        appModel.portalPosition
    }

    private var portalSize: Float {
        appModel.portalSize
    }

    var body: some View {
        RealityView { content in
            // ルートエンティティをシーンに追加
            content.add(rootEntity)

            print("RealityView: 初期セットアップ完了")
        } update: { content in
            // Portalの位置とサイズを更新
            if let portal = portalEntity {
                portal.position = portalPosition

                // Portalのサイズを更新
                if let portalPlane = portal.findEntity(named: "portalPlane") as? ModelEntity {
                    let newMesh = MeshResource.generatePlane(width: portalSize, height: portalSize)
                    portalPlane.model?.mesh = newMesh
                }

                // 写真のサイズと位置も更新
                if let portalWorld = portal.findEntity(named: "portalWorld"),
                   let photoEntity = portalWorld.findEntity(named: "enoshimaPhoto") as? ModelEntity {
                    let photoSize = portalSize * 2.0  // 50%表示のため2倍
                    let newPhotoMesh = MeshResource.generatePlane(width: photoSize, height: photoSize)
                    photoEntity.model?.mesh = newPhotoMesh
                }
            }
        }
        .onChange(of: appModel.shouldShowPortal) { _, shouldShow in
            if shouldShow && !isPortalVisible {
                showPortal()
            } else if !shouldShow && isPortalVisible {
                hidePortal()
            }
        }
    }

    /// Portalを表示
    private func showPortal() {
        guard !isPortalVisible else { return }

        let portal = createPortalEntity()
        portal.position = portalPosition
        rootEntity.addChild(portal)
        portalEntity = portal
        isPortalVisible = true

        print("Portalを表示しました - 位置: \(portalPosition), サイズ: \(portalSize)")
    }

    /// Portalを非表示
    private func hidePortal() {
        portalEntity?.removeFromParent()
        portalEntity = nil
        isPortalVisible = false

        print("Portalを非表示にしました")
    }

    /// Portalエンティティを作成（enoshima.JPGを表示）
    private func createPortalEntity() -> Entity {
        // Portal全体を包含するルートエンティティ
        let portalRoot = Entity()
        portalRoot.name = "portalRoot"

        // Portal内部の世界を作成（WorldComponentを追加してPortalを通してのみ見えるようにする）
        let portalWorld = Entity()
        portalWorld.name = "portalWorld"

        // WorldComponent: このエンティティをPortalを通してのみ表示
        portalWorld.components.set(WorldComponent())

        print("Portal World作成")

        // enoshima.JPGを背景として表示
        Task {
            do {
                try await createPhotoEnvironment(on: portalWorld)
                print("enoshima.JPG環境の読み込み成功")
            } catch {
                print("環境の読み込み失敗: \(error.localizedDescription)")
            }
        }

        // worldをルートに追加
        portalRoot.addChild(portalWorld)

        // Portalの入口（平面）を作成
        // generatePlane(width:, height:)で垂直な平面（XY平面）を生成
        // - width: X軸方向（横）
        // - height: Y軸方向（縦）
        // - 法線: +Z方向（手前向き）
        let portalMesh = MeshResource.generatePlane(
            width: portalSize,
            height: portalSize
        )

        // PortalMaterialを適用
        let portalMaterial = PortalMaterial()

        let portalPlane = ModelEntity(mesh: portalMesh, materials: [portalMaterial])
        portalPlane.name = "portalPlane"

        // PortalComponentを設定：portalWorldをターゲットに指定
        portalPlane.components.set(PortalComponent(target: portalWorld))

        // Portal平面をX軸周りに-90度回転させて壁面と平行にする
        portalPlane.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])

        // Portal平面を壁の少し手前に配置
        portalPlane.position = [0, 0, 0.01]

        portalRoot.addChild(portalPlane)

        print("Portal作成完了: portalPlane position=\(portalPlane.position)")

        return portalRoot
    }

    /// 写真を使った環境を作成
    private func createPhotoEnvironment(on root: Entity) async throws {
        print("写真環境作成を開始します")

        // enoshima.JPGを読み込む
        guard let imageURL = Bundle.main.url(forResource: "enoshima", withExtension: "JPG") else {
            print("エラー: enoshima.JPGが見つかりません")
            throw NSError(domain: "PortalError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load enoshima.JPG"])
        }
        print("enoshima.JPG URLを取得: \(imageURL)")

        // TextureResourceとして読み込み
        let texture = try await TextureResource(contentsOf: imageURL)
        print("TextureResourceの読み込み成功")

        // 写真を表示する平面を作成
        // Portal入口と同じサイズを基準に、200%に拡大（50%が見える状態）
        // これにより、覗き込んだ時に写真のエッジが見切れてPortalらしいエフェクトになる
        let scaleFactor: Float = 1.0 / 0.5  // 2倍
        let photoSize: Float = portalSize * scaleFactor
        let photoMesh = MeshResource.generatePlane(width: photoSize, height: photoSize)

        // UnlitMaterialを使用して写真を表示
        var photoMaterial = UnlitMaterial()
        photoMaterial.color = .init(texture: .init(texture))

        let photoEntity = ModelEntity(mesh: photoMesh, materials: [photoMaterial])
        photoEntity.name = "enoshimaPhoto"

        // 写真の向きをPortal平面と同じにする
        // Portal平面がX軸周りに-90度回転しているので、写真も同じ回転を適用
        photoEntity.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])

        // 写真の配置:
        // Portal平面の奥に配置（回転後の座標系でY軸の負方向が奥）
        // 40cm奥に配置
        photoEntity.position = [0, -0.4, 0]

        root.addChild(photoEntity)

        print("空間写真環境の構築が完了しました")
        print("写真エンティティ - 位置: \(photoEntity.position), スケール: \(photoEntity.scale)")
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}

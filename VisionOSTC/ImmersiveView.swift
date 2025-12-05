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

                // 空間写真（ImagePresentationComponent）側のスケールを更新
                if let portalWorld = portal.findEntity(named: "portalWorld"),
                   let spatialPhoto = portalWorld.findEntity(named: "spatialPhoto") {
                    let scaleFactor: Float = 1.0 // 必要に応じて調整
                    spatialPhoto.scale = [portalSize * scaleFactor, portalSize * scaleFactor, 1]
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

    /// Portalエンティティを作成（空間写真を表示）
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

        // 空間写真を背景として表示
        Task {
            do {
                try await createPhotoEnvironment(on: portalWorld)
                print("空間写真の読み込み成功")
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

    /// 空間写真環境を作成（ImagePresentationComponentを使用）
    private func createPhotoEnvironment(on root: Entity) async throws {
        print("空間写真環境の構築を開始します")

        // HEIC(空間写真)を読み込む
        guard let imageURL = Bundle.main.url(forResource: "space_picture", withExtension: "heic") else {
            print("エラー: space_picture.heic が見つかりません")
            throw NSError(domain: "PortalError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to load space_picture.heic"])
        }
        print("space_picture.heic URLを取得: \(imageURL)")

        // 空間写真を表示するためのエンティティを作成
        let imageEntity = Entity()
        imageEntity.name = "spatialPhoto"

        // ImagePresentationComponent を構成
        var presentationComponent = try await ImagePresentationComponent(contentsOf: imageURL)

        // 空間写真として表示するために desiredViewingMode を設定
        // availableViewingModes を確認して適切なモードを選択
        print("利用可能なビューイングモード: \(presentationComponent.availableViewingModes)")

        if presentationComponent.availableViewingModes.contains(.spatialStereo) {
            // ステレオスコピック空間写真として表示
            presentationComponent.desiredViewingMode = .spatialStereo
            print("空間写真モード: .spatialStereo を設定")
        } else if presentationComponent.availableViewingModes.contains(.spatial3DImmersive) {
            // 3D没入型として表示
            presentationComponent.desiredViewingMode = .spatial3DImmersive
            print("空間写真モード: .spatial3DImmersive を設定")
        } else {
            print("警告: 空間写真モードが利用できません。利用可能: \(presentationComponent.availableViewingModes)")
        }

        // エンティティにコンポーネントを設定
        imageEntity.components.set(presentationComponent)

        // Portal平面と同様に、X軸周りに-90度回転させて正面を向ける
        imageEntity.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])

        // Portalの奥側に配置（回転後の座標系でY負方向が奥）
        imageEntity.position = [0, -0.6, 0]

        // 背景画像を1.5倍に拡大
        imageEntity.scale = [1.5, 1.5, 1.5]

        root.addChild(imageEntity)

        print("空間写真環境の構築が完了しました")
        print("空間写真エンティティ - 位置: \(imageEntity.position), スケール: \(imageEntity.scale)")
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}

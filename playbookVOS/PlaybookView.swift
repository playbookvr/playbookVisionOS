//
//  PlaybookView.swift
//  playbookVOS
//
//  Created by Alex Carrizosa on 22/08/23.
//

import SwiftUI
import RealityKit
import RealityKitContent


struct PlaybookView: View {
    @Environment(\.dismiss) private var dismiss
    
    var viewModel: ViewModel
    
    static let featuresQuery = EntityQuery(where: .has(FeaturePointComponent.self))
    static let runtimeQuery = EntityQuery(where: .has(FeaturePointRuntimeComponent.self))
    
    @State private var subscriptions = [EventSubscription]()
    @State private var attachmentsProveder = AttachmentsProvider()
    
    
    var body: some View {
        @Bindable var viewModel = viewModel
            RealityView { content, _ in
                do{
                    let entity = try await Entity(named: "LucidCar", in: RealityKitContent.RealityKitContentBundle)
                    viewModel.rootEntity = entity
                    content.add(entity)
                    
                    entity.position = SIMD3<Float>(0, 0, -8)
                    
                    
                    /*
                    guard let url = Bundle.main.url(forResource: "skybox2", withExtension: "png"),
                                      let resource = try? await TextureResource(contentsOf: url) else {
                        fatalError("Unable to load skybox texture.")
                    }
                    var material = UnlitMaterial()
                    material.color = .init(texture: .init(resource))

                    let skyboxEntity = Entity()
                    skyboxEntity.components.set(ModelComponent(
                        mesh: .generateSphere(radius: 1000),
                        materials: [material]
                    ))

                    skyboxEntity.scale *= .init(x: -1, y: 1, z: 1)

                    content.add(skyboxEntity)
                     */
                    
                    subscriptions.append(content.subscribe(to: ComponentEvents.DidAdd.self,
                                                           componentType: FeaturePointComponent.self, { event in createFeatureDetailsView(for: event.entity)
                    }))

                    
                    guard let resource = try? await EnvironmentResource(named: "ImageBasedLight") else { fatalError("Unable to load image based lightning") }
                    let iblComponent = ImageBasedLightComponent(source: .single(resource), intensityExponent: 0)
                    entity.components.set(iblComponent)
                    entity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: entity))
                     
                     
                    
                } catch {
                    print("Error while loading RealityView \(error)")
                }
            } update: { content, attachments in
                viewModel.rootEntity?.scene?.performQuery(Self.runtimeQuery).forEach{ entity in
                    
                    guard let component = entity.components[FeaturePointRuntimeComponent.self] else { return }
                    
                    guard let attachmentEntity = attachments.entity(for: component.attachmentTag) else { return }
                    
                    viewModel.rootEntity?.addChild(attachmentEntity)
                    attachmentEntity.setPosition([0, 0.2, 0], relativeTo: entity)
                    
                }
            } attachments: {
                ForEach(attachmentsProveder.sortegTagViewPairs, id: \.tag) { pair in
                    pair.view
                }
            }
    }
    
    private func createFeatureDetailsView(for entity: Entity) {
        guard entity.components[FeaturePointRuntimeComponent.self] == nil else { return }
        
        guard let feature = entity.components[FeaturePointComponent.self] else { return }
        
        let tag: ObjectIdentifier = entity.id
        
        let view = FeatureDetailsView(
            name: feature.name,
            description: feature.description ?? "",
            viewModel: viewModel)
            .tag(tag)
        
        entity.components[FeaturePointRuntimeComponent.self] = FeaturePointRuntimeComponent(attachmentTag: tag)
        
        attachmentsProveder.attachments[tag] = AnyView(view)
    }
}

#Preview {
    PlaybookView(viewModel: ViewModel())
        .previewLayout(.sizeThatFits)
}

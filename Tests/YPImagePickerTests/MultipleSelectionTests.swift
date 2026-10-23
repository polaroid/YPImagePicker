import Photos
import XCTest
@testable import YPImagePicker

@MainActor
final class MultipleSelectionTests: XCTestCase {
    func testToggleBeforeLibraryInitializationPreservesSelection() {
        assertToggleIsIgnored(fetchCount: nil, selectedIndex: 0)
    }

    func testToggleWithEmptyLibraryPreservesSelection() {
        assertToggleIsIgnored(fetchCount: 0, selectedIndex: 0)
    }

    func testToggleWithNegativeIndexPreservesSelection() {
        assertToggleIsIgnored(fetchCount: 2, selectedIndex: -1)
    }

    func testToggleWithStaleIndexPreservesSelection() {
        assertToggleIsIgnored(fetchCount: 2, selectedIndex: 2)
        assertToggleIsIgnored(fetchCount: 2, selectedIndex: 3)
    }

    private func assertToggleIsIgnored(
        fetchCount: Int?,
        selectedIndex: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for inverseSorted in [false, true] {
            for multipleSelectionEnabled in [false, true] {
                let library = YPLibraryVC()
                library.requiresInverseSorting = inverseSorted
                library.multipleSelectionEnabled = multipleSelectionEnabled
                library.currentlySelectedIndex = selectedIndex
                library.selection = [YPLibrarySelection(index: 0, assetIdentifier: "existing-photo")]
                if let fetchCount = fetchCount {
                    library.mediaManager.set(fetchResult: AssetFetchResultStub(count: fetchCount))
                }

                library.multipleSelectionButtonTapped()

                XCTAssertEqual(library.multipleSelectionEnabled, multipleSelectionEnabled, file: file, line: line)
                XCTAssertEqual(library.currentlySelectedIndex, selectedIndex, file: file, line: line)
                XCTAssertEqual(library.selection.map(\.assetIdentifier), ["existing-photo"], file: file, line: line)
                XCTAssertFalse(library.isViewLoaded, file: file, line: line)
            }
        }
    }
}

private final class AssetFetchResultStub: PHFetchResult<PHAsset>, @unchecked Sendable {
    private let assetCount: Int

    init(count: Int) {
        assetCount = count
        super.init()
    }

    override var count: Int { assetCount }
}

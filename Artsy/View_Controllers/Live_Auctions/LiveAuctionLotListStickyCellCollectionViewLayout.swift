import UIKit

class LiveAuctionLotListStickyCellCollectionViewLayout: UICollectionViewFlowLayout {
    private var currentIndex = 0

    override init() {
        super.init()

        self.scrollDirection = .Vertical
        self.minimumInteritemSpacing = 0
        self.minimumLineSpacing = 0
        self.sectionInset = UIEdgeInsets(top: 1, left: 0, bottom: 40, right: 0)
        // itemSize must be set in prepareLayout
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }

}


private typealias PublicFunctions = LiveAuctionLotListStickyCellCollectionViewLayout
extension PublicFunctions {

    func setActiveIndex(index: Int) {
        currentIndex = index
        invalidateLayout()
    }
}


private typealias PrivateFunctions = LiveAuctionLotListStickyCellCollectionViewLayout
extension PrivateFunctions {

    func setActiveAttributes(attributes: UICollectionViewLayoutAttributes) {
        guard let collectionView = collectionView else { return }

        let contentOffset = collectionView.contentOffset.y

        if CGRectGetMinY(attributes.frame) < contentOffset {
            // Attributes want to be above the visible rect, so let's stick it to the top.
            attributes.frame.origin.y = contentOffset
        } else if CGRectGetMaxY(attributes.frame) > CGRectGetHeight(collectionView.frame) + contentOffset {
            // Attributes want to be below the visible rect, so let's stick it to the bottom (height + contentOffset - height of attributes)
            attributes.frame.origin.y = CGRectGetHeight(collectionView.frame) + contentOffset - CGRectGetHeight(attributes.frame)
        }
        
        attributes.zIndex = 1
    }
}


private typealias Overrides = LiveAuctionLotListStickyCellCollectionViewLayout
extension Overrides {

    override func prepareLayout() {
        super.prepareLayout()

        let width = collectionViewContentSize().width
        let height = LotListCollectionViewCell.Height

        itemSize = CGSize(width: width, height: height)
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let superAttributesArray = super.layoutAttributesForElementsInRect(rect) else { return nil }
        var attributesArray = superAttributesArray.flatMap { $0 }

        // Guarantee any selected cell is presented, regardless of the rect.
        if (attributesArray.map { $0.indexPath.item }).contains(currentIndex) == false {
            let indexPath = NSIndexPath(forItem: currentIndex, inSection: 0)
            attributesArray += [layoutAttributesForItemAtIndexPath(indexPath)!] // TODO: Don't like the crash operator here.
        }

        attributesArray
            .filter { $0.indexPath.item == currentIndex }
            .forEach(setActiveAttributes)

        return attributesArray
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItemAtIndexPath(indexPath)?.copy() as? UICollectionViewLayoutAttributes else { return nil }

        if attributes.indexPath.item == currentIndex {
            setActiveAttributes(attributes)
        }

        return attributes
    }

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
}

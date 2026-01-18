import SwiftUI

extension StructuredText {
  /// A layout description for a rendered table.
  ///
  /// `StructuredText` computes a `TableLayout` from the measured sizes of each cell and provides
  /// it to ``StructuredText/TableStyle`` when rendering table backgrounds and overlays. Styles
  /// can use it to draw dividers or row backgrounds that align with the table grid.
  public struct TableLayout: Hashable {
    private struct Row: Hashable {
      var minY: CGFloat
      var height: CGFloat
    }

    private struct Column: Hashable {
      var minX: CGFloat
      var width: CGFloat
    }

    /// The bounding rectangle that contains the whole table.
    public let bounds: CGRect

    /// The valid row indices for this table.
    public var rowIndices: Range<Int> { rows.indices }

    /// The valid column indices for this table.
    public var columnIndices: Range<Int> { columns.indices }

    /// The number of rows in the table.
    public var numberOfRows: Int { rows.count }

    /// The number of columns in the table.
    public var numberOfColumns: Int { columns.count }

    private let rows: [Row]
    private let columns: [Column]

    init(_ cellBounds: [TableCell.Identifier: Anchor<CGRect>], geometry: GeometryProxy) {
      self.init(cellBounds.mapValues { geometry[$0] })
    }

    init(_ cellBounds: [TableCell.Identifier: CGRect] = [:]) {
      let rowCount = Set(cellBounds.keys.map(\.row)).count
      let columnCount = Set(cellBounds.keys.map(\.column)).count

      var rows = Array(
        repeating: Row(minY: .greatestFiniteMagnitude, height: 0),
        count: rowCount
      )
      var columns = Array(
        repeating: Column(minX: .greatestFiniteMagnitude, width: 0),
        count: columnCount
      )

      for (identifier, bounds) in cellBounds {
        let row = identifier.row
        let column = identifier.column

        rows[row].minY = min(rows[row].minY, bounds.minY)
        rows[row].height = max(rows[row].height, bounds.height)

        columns[column].minX = min(columns[column].minX, bounds.minX)
        columns[column].width = max(columns[column].width, bounds.width)
      }

      self.rows = rows
      self.columns = columns
      self.bounds = cellBounds.values.reduce(CGRect.null, CGRectUnion)
    }

    /// Returns the bounds of the cell at the given row and column.
    public func cellBounds(row: Int, column: Int) -> CGRect {
      CGRect(
        origin: .init(x: columns[column].minX, y: rows[row].minY),
        size: CGSize(width: columns[column].width, height: rows[row].height)
      )
    }

    /// Returns the bounds of the given row.
    public func rowBounds(_ row: Int) -> CGRect {
      columnIndices
        .compactMap { cellBounds(row: row, column: $0) }
        .reduce(.null, CGRectUnion)
    }

    /// Returns the bounds of the given column.
    public func columnBounds(_ column: Int) -> CGRect {
      rowIndices
        .compactMap { cellBounds(row: $0, column: column) }
        .reduce(.null, CGRectUnion)
    }

    /// Returns rectangles representing vertical dividers between columns.
    public func verticalDividers() -> [CGRect] {
      guard columns.count > 1 else { return [] }

      var dividers: [CGRect] = []

      for column in columnIndices.dropLast() {
        let leftMaxX = columns[column].minX + columns[column].width
        let rightMinX = columns[column + 1].minX

        let width = rightMinX - leftMaxX
        guard width > 0 else { continue }

        dividers.append(
          CGRect(
            x: leftMaxX,
            y: bounds.minY,
            width: width,
            height: bounds.height
          )
        )
      }

      return dividers
    }

    /// Returns rectangles representing horizontal dividers between rows.
    public func horizontalDividers() -> [CGRect] {
      guard rows.count > 1 else { return [] }

      var dividers: [CGRect] = []

      for row in rowIndices.dropLast() {
        let topMaxY = rows[row].minY + rows[row].height
        let bottomMinY = rows[row + 1].minY

        let height = bottomMinY - topMaxY
        guard height > 0 else { continue }

        dividers.append(
          CGRect(
            x: bounds.minX,
            y: topMaxY,
            width: bounds.width,
            height: height
          )
        )
      }

      return dividers
    }

    /// Returns rectangles for all dividers in the table.
    public func dividers() -> [CGRect] {
      horizontalDividers() + verticalDividers()
    }
  }
}

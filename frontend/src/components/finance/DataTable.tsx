import { ChevronDown, ChevronUp, ChevronsUpDown } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Select } from "@/components/ui/select";
import { cn } from "@/lib/utils";

export type DataTableColumn<T> = {
  key: string;
  header: string;
  sortable?: boolean;
  align?: "left" | "right" | "center";
  width?: string;
  className?: string;
  render: (row: T) => React.ReactNode;
};

function parseSort(sort: string): { field: string; direction: "asc" | "desc" } {
  if (sort.endsWith("_asc")) return { field: sort.slice(0, -4), direction: "asc" };
  if (sort.endsWith("_desc")) return { field: sort.slice(0, -5), direction: "desc" };
  return { field: sort, direction: "desc" };
}

function toggleSort(current: string, field: string): string {
  const parsed = parseSort(current);
  if (parsed.field === field) {
    return `${field}_${parsed.direction === "desc" ? "asc" : "desc"}`;
  }
  const textFirst = ["title", "source", "kind", "account", "category", "type"];
  return `${field}_${textFirst.includes(field) ? "asc" : "desc"}`;
}

const PAGE_SIZE_OPTIONS = [
  { value: "10", label: "10 / page" },
  { value: "25", label: "25 / page" },
  { value: "50", label: "50 / page" },
  { value: "100", label: "100 / page" },
];

export function DataTable<T>({
  columns,
  rows,
  rowKey,
  loading = false,
  empty = "No rows",
  sort,
  onSort,
  page,
  pageSize,
  total,
  onPageChange,
  onPageSizeChange,
  pageSizeOptions = PAGE_SIZE_OPTIONS,
  onRowClick,
  selectedKey,
  minWidth = 880,
  idPrefix = "table",
  embedded = false,
}: {
  columns: DataTableColumn<T>[];
  rows: T[];
  rowKey: (row: T) => string;
  loading?: boolean;
  empty?: string;
  sort?: string;
  onSort?: (next: string) => void;
  page: number;
  pageSize: number;
  total: number;
  onPageChange: (page: number) => void;
  onPageSizeChange: (size: number) => void;
  pageSizeOptions?: { value: string; label: string }[];
  onRowClick?: (row: T) => void;
  selectedKey?: string | null;
  minWidth?: number;
  idPrefix?: string;
  embedded?: boolean;
}) {
  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  const safePage = Math.min(page, totalPages);
  const start = total === 0 ? 0 : (safePage - 1) * pageSize + 1;
  const end = Math.min(safePage * pageSize, total);
  const parsed = sort ? parseSort(sort) : null;

  return (
    <div className={cn("ledger-table-shell", embedded && "is-embedded")}>
      <div className="ledger-table-scroll">
        <table className="ledger-table" style={{ minWidth }}>
          <thead>
            <tr>
              {columns.map((column) => {
                const align = column.align ?? "left";
                const active = parsed?.field === column.key;
                const sortable = Boolean(column.sortable && onSort);
                const SortIcon = !sortable
                  ? null
                  : active && parsed?.direction === "asc"
                    ? ChevronUp
                    : active && parsed?.direction === "desc"
                      ? ChevronDown
                      : ChevronsUpDown;
                return (
                  <th
                    key={column.key}
                    style={column.width ? { width: column.width } : undefined}
                    className={cn(
                      align === "right" && "text-right",
                      align === "center" && "text-center",
                      column.className
                    )}
                  >
                    {sortable ? (
                      <button
                        type="button"
                        className={cn("ledger-sort", active && "is-active")}
                        onClick={() => onSort?.(toggleSort(sort ?? "date_desc", column.key))}
                      >
                        <span>{column.header}</span>
                        {SortIcon && <SortIcon size={13} />}
                      </button>
                    ) : (
                      <span>{column.header}</span>
                    )}
                  </th>
                );
              })}
            </tr>
          </thead>
          <tbody>
            {loading && (
              <tr className="ledger-table-empty">
                <td colSpan={columns.length}>Loading…</td>
              </tr>
            )}
            {!loading && rows.length === 0 && (
              <tr className="ledger-table-empty">
                <td colSpan={columns.length}>{empty}</td>
              </tr>
            )}
            {!loading &&
              rows.map((row) => {
                const key = rowKey(row);
                return (
                  <tr
                    key={key}
                    className={cn(
                      onRowClick && "is-clickable",
                      selectedKey === key && "is-selected"
                    )}
                    onClick={onRowClick ? () => onRowClick(row) : undefined}
                  >
                    {columns.map((column) => (
                      <td
                        key={column.key}
                        className={cn(
                          column.align === "right" && "text-right",
                          column.align === "center" && "text-center",
                          column.className
                        )}
                      >
                        {column.render(row)}
                      </td>
                    ))}
                  </tr>
                );
              })}
          </tbody>
        </table>
      </div>
      <div className="ledger-table-footer">
        <p>
          {total === 0 ? "No results" : `Showing ${start}–${end} of ${total}`}
        </p>
        <div className="ledger-table-pager">
          <Select
            id={`${idPrefix}-page-size`}
            className="h-9 min-w-[120px]"
            value={String(pageSize)}
            onChange={(e) => onPageSizeChange(Number(e.target.value))}
            options={pageSizeOptions}
          />
          <Select
            id={`${idPrefix}-page`}
            className="h-9 min-w-[120px]"
            value={String(safePage)}
            onChange={(e) => onPageChange(Number(e.target.value))}
            options={Array.from({ length: totalPages }, (_, index) => ({
              value: String(index + 1),
              label: `Page ${index + 1}`,
            }))}
          />
          <Button
            variant="outline"
            size="sm"
            disabled={safePage <= 1}
            onClick={() => onPageChange(safePage - 1)}
          >
            Previous
          </Button>
          <Button
            variant="outline"
            size="sm"
            disabled={safePage >= totalPages}
            onClick={() => onPageChange(safePage + 1)}
          >
            Next
          </Button>
        </div>
      </div>
    </div>
  );
}

---
sidebar_position: 8
---

# Analytics

Route: `/analytics`

The analytics dashboard provides visual insights into spending patterns.

## Time Range

Users can filter by **3 months**, **6 months** (default), or **12 months**. The server fetches 12 months of data; the client filters by the selected range.

## Charts

All charts format monetary values using `Intl.NumberFormat` with the user's `default_currency` from their profile. Axis labels and tooltips display the correct currency symbol and formatting (e.g. ₹1,200 for INR, $1,200 for USD).

### Category Pie Chart

- Top 8 spending categories by total amount
- Personal expenses only
- Interactive tooltip with currency-formatted amounts

### Monthly Burn Rate

- Line chart showing monthly personal spending over time
- Sorted chronologically
- Y-axis labels formatted with user's currency

### Personal vs Group Comparison

- Bar chart comparing personal and group spending per month
- Side-by-side bars for visual comparison

## Data Sources

- **Personal expenses**: `payer_id = user.id` AND `group_id IS NULL`
- **Group expenses**: `payer_id = user.id` AND `group_id IS NOT NULL`
- Both fetched with category information for breakdown

---
sidebar_position: 7
---

# Analytics

Route: `/analytics`

The analytics dashboard provides visual insights into spending patterns.

## Time Range

Users can filter by **3 months**, **6 months** (default), or **12 months**. The server fetches 12 months of data; the client filters by the selected range.

## Charts

### Category Pie Chart

- Top 8 spending categories by total amount
- Personal expenses only
- Interactive tooltip with amounts

### Monthly Burn Rate

- Line chart showing monthly personal spending over time
- Sorted chronologically

### Personal vs Group Comparison

- Bar chart comparing personal and group spending per month
- Side-by-side bars for visual comparison

## Data Sources

- **Personal expenses**: `payer_id = user.id` AND `group_id IS NULL`
- **Group expenses**: `payer_id = user.id` AND `group_id IS NOT NULL`
- Both fetched with category information for breakdown

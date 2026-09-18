# wt-hansen-deforestation

Forest cover trend analysis workflow built on the Hansen Global Forest Change
dataset. Extracts yearly forest loss/survival per region of interest and fits
a trend model (Linear, GLM, GAM, or GAMM) to the resulting time series.

## Trend Analysis

The `Trend Analysis` step lets you pick one of four regression models
(Linear, GLM, GAM, GAMM). Every region still gets its own trend chart in the
dashboard, filtered to that region - but GAMM is wired differently from the
other three under the hood, because of what a "random effect" needs to mean
anything statistically.

Linear/GLM/GAM each **fit independently per region**: `trend_fit`/
`trend_predictions` are `mapvalues`'d over `forest_cover_trends`'s per-region
output, one fit per region, no cross-region interaction.

GAMM (Generalized Additive Mixed Model) adds a random effect per site - a
term estimating how much sites typically vary from each other. Variance is a
property of a *set* of values: fit on just one region, there's nothing to
estimate that from. So GAMM **fits once, combined across every region**
(`forest_cover_trends_combined` via `concat_dataframes`, then
`trend_fit_combined`), using the `name` column `extract_forest_cover_trends`
already propagates as the site label (real cross-region variance now, not a
placeholder) - gated by the `is_gamm_trend_model`/`is_not_gamm_trend_model`
`skipif` conditions (in `ecoscope.platform.tasks.analysis._trend_analysis`)
so exactly one of the two fit branches runs for a given model selection.

Fitting combined doesn't mean charting combined, though - an earlier attempt
did that and the resulting chart pooled every region's very different
cumulative-loss trajectories onto one x-axis, which looked like noise rather
than a trend. Instead, `predict_trend_model` takes an optional `dataframe`
parameter: pass a single region's own rows and it returns *that region's*
group-specific prediction pulled out of the shared combined fit (via
`GAMMRegressor.predict_with_ci`'s own `site_ids` argument) - so
`trend_predictions_gamm` still predicts **per region**, same shape as the
other three models' output, just reading from one shared fit instead of an
independent one. `trend_predictions`/`trend_predictions_gamm` (whichever one
is skipped, per the model selection above) are merged back into one
per-region series via `groupbykey_passthrough_skip` +`concat_dataframes`
(`trend_predictions_merged`/`_final`), so the chart/persist/widget steps
downstream are unaware of any of this branching.

One real trade-off worth knowing: pooling regions with very different
absolute loss scales into one shared spline/family fit can miscalibrate the
low-scale outliers - observed once as a region's GAMM-predicted trend
briefly dipping below zero (not physically possible for a cumulative loss
percentage), something the independent per-region fits don't do since each
is calibrated to its own scale.

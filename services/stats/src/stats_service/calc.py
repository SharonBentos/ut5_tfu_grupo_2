import statistics
from collections import Counter


def compute_stats(scores: list[float]) -> dict:
    """Fórmulas de la UT4 (antes dentro de main.movie_stats)."""
    count = len(scores)
    if count == 0:
        return {
            "rating_count": 0,
            "avg_rating": None,
            "min_rating": None,
            "max_rating": None,
            "median_rating": None,
            "stddev_rating": None,
            "score_distribution": {},
        }

    if count >= 2:
        try:
            std = round(statistics.pstdev(scores), 2)
        except statistics.StatisticsError:
            std = 0.0
    else:
        std = 0.0

    dist_counter = Counter(int(s // 1) for s in scores)
    return {
        "rating_count": count,
        "avg_rating": round(statistics.fmean(scores), 2),
        "min_rating": min(scores),
        "max_rating": max(scores),
        "median_rating": round(statistics.median(scores), 2),
        "stddev_rating": std,
        "score_distribution": {str(k): v for k, v in sorted(dist_counter.items())},
    }

class CusumDetector:
    def __init__(self, threshold: float, drift: float = 0.0):
        self.threshold = threshold
        self.drift = drift
        self.pos_sum = 0.0
        self.neg_sum = 0.0
        self.last_mean = None

    def update(self, value: float) -> bool:
        if self.last_mean is None:
            self.last_mean = value
            return False

        diff = value - self.last_mean - self.drift
        self.pos_sum = max(0, self.pos_sum + diff)
        self.neg_sum = min(0, self.neg_sum + diff)

        if self.pos_sum > self.threshold or abs(self.neg_sum) > self.threshold:
            # Сигнал аномалії, скидаємо накопичення
            self.pos_sum = 0
            self.neg_sum = 0
            return True

        return False

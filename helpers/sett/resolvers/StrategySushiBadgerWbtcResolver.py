from helpers.sett.resolvers.StrategyCoreResolver import StrategyCoreResolver


def confirm_harvest_badger_lp(before, after):
    """
    Harvest Should;
    - Increase the balanceOf() underlying asset in the Strategy
    - Reduce the amount of idle BADGER to zero
    - Increase the ppfs on sett
    """

    assert after.strategy.balanceOf >= before.strategy.balanceOf
    if before.sett.pricePerFullShare:
        assert after.sett.pricePerFullShare > before.sett.pricePerFullShare


class StrategySushiBadgerWbtcResolver(StrategyCoreResolver):
    def confirm_harvest(self, before, after):
        super().confirm_harvest(before, after)
        # Strategy want should increase
        before_balance = before.get("strategy.balanceOf")
        assert (
            after.get("strategy.balanceOf") >= before_balance if before_balance else 0
        )

        # PPFS should not decrease
        assert after.get("sett.pricePerFullShare") >= before.get(
            "sett.pricePerFullShare"
        )

        # Sushi in badger tree should increase
        # Strategy should have no sushi
        # Strategy should have no sushi in Chef
    
    def confirm_tend(self, before, after):

        # Increase xSushi position in strategy
        assert after.balances("xsushi", "strategy") > before.balances("xsushi", "strategy")

    def get_strategy_destinations(self):
        strategy = self.manager.strategy
        return {
            "chef": strategy.chef(),
            "bar": strategy.xsushi(),
            "stakingRewards": strategy.geyser(),
        }
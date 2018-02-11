import hooks;
import generic_hooks;
import sites;
from sites import ISiteHook, SiteHook;

class AddSite : BonusEffect {
  Document doc("Add a site on the target planet.");
	Argument type(AT_Anomaly, "distributed", doc="Type of site to spawn. Defaults to randomized.");
	Argument start_scanned(AT_Boolean, "False", doc="Whether the site starts out scanned by the empire that triggered this.");
  Argument chance(AT_Range, "1.0", doc="Chance that this hook may activate.");
  Argument status(AT_Status, "", doc="Type of status effect to create on failure.");

	const SiteType@ siteType;

	bool instantiate() {
		if(!type.str.equals_nocase("distributed")) {
			@siteType = getSiteType(type.str);
			if(siteType is null) {
				error(" Error: Could not find site type: '"+escape(type.str)+"'");
				return false;
			}
		}
		return BonusEffect::instantiate();
	}

#section server
	void activate(Object@ obj, Empire@ emp) const override {
		if(obj is null)
			return;
    Planet@ planet = cast<Planet>(obj);
    if (planet is null)
      return;

    double ch = chance.fromRange();
    if (ch < 1.0 && randomd() > ch) {
      if (status.integer > 0) {
        obj.addStatus(-1, uint(status.integer));
        return;
      }
    }

    const SiteType@ type = siteType;
		if(type is null) {
			do {
				@type = getDistributedSiteType(getSiteTypes(SK_TerrestrialSite));
			}
			while(type.unique);
		}

    uint siteId = planet.spawnSite(type.id);
    if(start_scanned.boolean && emp !is null)
			planet.addProgressToSite(emp, siteId, 10000000000.f);
	}
#section all
};

class ActiveConfigOption : EmpireTrigger {
  Document doc("Executes a hook only if a config option has a particular value.");
	Argument hookID(AT_Hook, "bonus_effects::EmpireTrigger");
  Argument option(AT_Custom, doc="Config option to check.");
	Argument value(AT_Decimal, "1.0", doc="Value for the option to check for.");

  BonusEffect@ hook;

	bool withHook(const string& str) {
		@hook = cast<BonusEffect>(parseHook(str, "bonus_effects::"));
		if(hook is null) {
			error("ActiveOption(): could not find inner hook: " + escape(str));
			return false;
		}
		return true;
	}

	bool instantiate() {
		if(!withHook(arguments[0].str))
			return false;
    return BonusEffect::instantiate();
	}

#section server
	void activate(Object@ obj, Empire@ emp) const override {
    if (config::get(option.str) == value.decimal)
		  hook.activate(obj, emp);
	}
#section all
};

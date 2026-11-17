package pcb

func withGlobal(flag *bool, val bool, fn func()) {
	prev := *flag
	*flag = val
	if globalTemp != nil {
		var gval = uint64(0)
		if val {
			gval = 1
		}
		globalTemp(flagName[flag], gval, fn)
	} else {
		fn()
	}
	*flag = prev
}

func withGlobalInt(flag *int, val int, fn func()) {
	prev := *flag
	*flag = val
	if globalTemp != nil {
		globalTemp(flagNameInt[flag], uint64(val), fn)
	} else {
		fn()
	}
	*flag = prev
}

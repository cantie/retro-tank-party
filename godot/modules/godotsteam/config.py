def can_build(env, platform):
	return platform=="x11" or platform=="windows" or platform=="osx" or platform=="server"

def configure(env):
	module_path = Dir('.').srcnode().abspath
	env.Append(CPPPATH=["%s/sdk/public/" % module_path])

	# If compiling Linux
	if env["platform"]== "x11" or env["platform"] == "server":
		env.Append(LIBS=["steam_api"])
		env.Append(RPATH=["."])
		if env["bits"]=="32":
			env.Append(LIBPATH=["%s/sdk/redistributable_bin/linux32" % module_path])
		else: # 64 bit
			env.Append(LIBPATH=["%s/sdk/redistributable_bin/linux64" % module_path])

	# If compiling Windows
	elif env["platform"] == "windows":
		# Mostly VisualStudio
		if env["CC"] == "cl":
			if env["bits"]=="32":
				env.Append(LINKFLAGS=["steam_api.lib"])
				env.Append(LIBPATH=["%s/sdk/redistributable_bin" % module_path])
			else: # 64 bit
				env.Append(LINKFLAGS=["steam_api64.lib"])
				env.Append(LIBPATH=["%s/sdk/redistributable_bin/win64" % module_path])
		
		# Mostly "GCC"
		else:
			if env["bits"]=="32":
				env.Append(LIBS=["steam_api"])
				env.Append(LIBPATH=["%s/sdk/redistributable_bin" % module_path])
			else: # 64 bit
				env.Append(LIBS=["steam_api64"])
				env.Append(LIBPATH=["%s/sdk/redistributable_bin/win64" % module_path])

	# If compiling OSX
	elif env["platform"] == "osx":
		env.Append(LIBS=["steam_api"])
		env.Append(LIBPATH=['%s/sdk/redistributable_bin/osx' % module_path])

def get_doc_classes():
	return [
		"Steam",
	]

def get_doc_path():
	return "doc_classes"

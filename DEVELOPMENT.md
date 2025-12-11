# Development Guide

## Developing Nimini alongside NimRLive

Since NimRLive is used to flesh out and test Nimini's raylib scripting support, you'll want to develop both projects together. Here are the recommended approaches:

### Option 1: Local Nimini Clone (Recommended for Active Development)

This approach gives you full control over Nimini's source and makes testing changes immediate.

1. **Clone Nimini alongside nimrlive**
   ```bash
   cd /workspaces
   git clone https://github.com/maddestlabs/nimini.git
   ```

2. **Use Nim path to reference local Nimini**
   
   Create or edit `nim.cfg` to add:
   ```nim
   # Use local nimini for development (comment out for production)
   --path:"../nimini/src"
   ```

3. **Development workflow**
   ```bash
   # Make changes to nimini source in /workspaces/nimini/src
   # Test immediately in nimrlive
   cd /workspaces/nimrlive
   nim c -r nimrlive.nim
   
   # When you find bugs or need new features:
   # 1. Edit nimini source
   # 2. Test in nimrlive
   # 3. Commit to nimini repo
   # 4. No need to reinstall!
   ```

4. **Switch back to package version**
   - Comment out the `--path:"../nimini/src"` line in `nim.cfg`
   - Nimble-installed version will be used instead

### Option 2: Nimble Develop Mode

Nimble has a development mode that links packages:

```bash
cd /workspaces
git clone https://github.com/maddestlabs/nimini.git
cd nimini
nimble develop
```

This installs nimini in "develop" mode - changes to the source are immediately available.

### Option 3: Vendor Nimini Source (For Experimentation)

Copy nimini source directly into this repo (gitignored):

```bash
cd /workspaces/nimrlive
git clone https://github.com/maddestlabs/nimini.git vendor/nimini
echo "vendor/" >> .gitignore
```

Add to `nim.cfg`:
```nim
--path:"vendor/nimini/src"
```

## Recommended: Option 1 (Local Clone + Path)

**Why this is best:**
- ✅ Easy to switch between dev and production versions
- ✅ Keeps repos separate (proper git workflow)
- ✅ Immediate testing without reinstall
- ✅ Clean commits to both repos
- ✅ Can work on multiple projects using nimini

**Workflow:**
1. Develop features in `/workspaces/nimini`
2. Test in `/workspaces/nimrlive` 
3. When feature works, commit to nimini repo
4. Tag release in nimini
5. Update nimrlive to use new version

## Testing Your Changes

### Native Testing
```bash
cd /workspaces/nimrlive
nim c -r nimrlive.nim nimr.nim
```

### WebAssembly Testing
```bash
source setup_emscripten.sh
./build.sh
cd docs && python3 -m http.server 8000
# Open http://localhost:8000
```

### Quick Iteration Cycle
```bash
# Terminal 1: Edit nimini source
vim /workspaces/nimini/src/nimini.nim

# Terminal 2: Test in nimrlive
cd /workspaces/nimrlive
nim c -r nimrlive.nim test_script.nim
```

## Tracking Nimini Development

Consider creating issues/features in nimrlive that track needed nimini features:

```markdown
## TODO: Nimini Features for NimRLive

- [ ] Add DrawCircleV binding
- [ ] Support raylib Color types in scripting
- [ ] Handle texture loading in scripts
- [ ] Add error handling for missing symbols
```

## CI/CD Considerations

Your GitHub Actions workflow will continue to use the nimble-installed version, which is correct. This ensures:
- Production builds use stable nimini versions
- Local development can experiment freely
- You control when to update production

When you want to update production:
1. Tag a new nimini release
2. Update `nimrlive.nimble` to require the new version
3. CI will automatically use it

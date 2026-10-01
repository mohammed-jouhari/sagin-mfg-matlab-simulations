function outDir = prepare_output_dir(outDir)
%PREPARE_OUTPUT_DIR Return an absolute, writable folder for the outputs.
%   The folder is created if needed. If it cannot be written (read-only
%   location, synced folder that blocks new files, missing rights), a
%   folder in the temporary directory is used instead and a warning says
%   where the files go.
if isempty(regexp(outDir, '^([A-Za-z]:|[\\/])', 'once'))
    outDir = fullfile(pwd, outDir);              % make the path absolute
end
if ~exist(outDir, 'dir')
    [ok, msg] = mkdir(outDir);
    if ~ok
        warning('prepare_output_dir:mkdir', 'Cannot create %s (%s)', outDir, msg);
    end
end
if ~is_writable(outDir)
    alt = fullfile(tempdir, 'sagin_mfg_figures');
    if ~exist(alt, 'dir'), mkdir(alt); end
    warning('prepare_output_dir:readonly', ...
        'Folder %s is not writable. Outputs are written to %s', outDir, alt);
    outDir = alt;
end
end

function ok = is_writable(d)
%IS_WRITABLE Try to create and delete a small file in folder d.
ok = false;
if ~exist(d, 'dir'), return; end
probe = fullfile(d, sprintf('write_test_%d.tmp', floor(1e6*rand)));
fid = fopen(probe, 'w');
if fid > 0
    fclose(fid);
    delete(probe);
    ok = true;
end
end

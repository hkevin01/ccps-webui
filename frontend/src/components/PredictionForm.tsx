import { useForm } from 'react-hook-form';
import { useEffect, useState } from 'react';

type Props = {
  onPredict: (data: any) => void;
  isLoading?: boolean; // Add isLoading prop as optional
};

type FormValues = {
  region: string;
  date: string;
  seaLevel: number;
  erosionRate: number;
  precipitation: number;
};

export const PredictionForm: React.FC<Props> = ({ onPredict, isLoading = false }) => {
  const { register, handleSubmit, reset, formState: { errors } } = useForm<FormValues>();
  const [regions, setRegions] = useState<string[]>([]);

  useEffect(() => {
    // Simulate a fetch from USGS API or use static USGS region list
    setRegions(['Atlantic Coast', 'Gulf Coast', 'Pacific Coast', 'Great Lakes', 'Arctic Coast']);
  }, []);

  const onSubmit = (data: FormValues) => {
    onPredict(data);
    reset();
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="row g-3">
      <div className="col-md-4">
        <select
          className={`form-select ${errors.region ? 'is-invalid' : ''}`}
          {...register('region', { required: 'Region is required' })}
        >
          <option value="">Select Region</option>
          {regions.map((region) => (
            <option key={region} value={region}>
              {region}
            </option>
          ))}
        </select>
        {errors.region && <div className="invalid-feedback">{errors.region.message}</div>}
      </div>
      <div className="col-md-4">
        <input
          type="date"
          className={`form-control ${errors.date ? 'is-invalid' : ''}`}
          {...register('date', {
            required: 'Date is required',
            validate: {
              inPast: (value) => new Date(value) <= new Date() || 'Date cannot be in the future',
            },
          })}
        />
        {errors.date && <div className="invalid-feedback">{errors.date.message}</div>}
      </div>
      <div className="col-md-4">
        <input
          type="number"
          step="any"
          className={`form-control ${errors.seaLevel ? 'is-invalid' : ''}`}
          placeholder="Sea Level (meters)"
          {...register('seaLevel', {
            required: 'Sea Level is required',
            min: { value: 0, message: 'Sea Level must be at least 0 meters' },
            max: { value: 100, message: 'Sea Level cannot exceed 100 meters' },
          })}
        />
        <small className="form-text text-muted">
          Enter the current sea level in meters (USGS typical range: 0-100).
        </small>
        {errors.seaLevel && <div className="invalid-feedback">{errors.seaLevel.message}</div>}
      </div>
      <div className="col-md-4">
        <input
          type="number"
          step="any"
          className={`form-control ${errors.erosionRate ? 'is-invalid' : ''}`}
          placeholder="Erosion Rate (m/year)"
          {...register('erosionRate', {
            required: 'Erosion Rate is required',
            min: { value: -10, message: 'Erosion Rate cannot be less than -10 m/year' },
            max: { value: 10, message: 'Erosion Rate cannot exceed 10 m/year' },
          })}
        />
        <small className="form-text text-muted">
          Rate of shoreline change in meters per year (negative for erosion, positive for accretion).
        </small>
        {errors.erosionRate && <div className="invalid-feedback">{errors.erosionRate.message}</div>}
      </div>
      <div className="col-md-4">
        <input
          type="number"
          step="any"
          className={`form-control ${errors.precipitation ? 'is-invalid' : ''}`}
          placeholder="Precipitation (mm)"
          {...register('precipitation', {
            required: 'Precipitation is required',
            min: { value: 0, message: 'Precipitation cannot be less than 0 mm' },
            max: { value: 500, message: 'Precipitation cannot exceed 500 mm' },
          })}
        />
        <small className="form-text text-muted">
          Enter precipitation in millimeters (USGS typical range: 0-500).
        </small>
        {errors.precipitation && <div className="invalid-feedback">{errors.precipitation.message}</div>}
      </div>
      <div className="col-md-4 d-flex align-items-end">
        <button type="submit" className="btn btn-primary w-100" disabled={isLoading}>
          {isLoading ? (
            <>
              <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
              Predicting...
            </>
          ) : (
            'Predict'
          )}
        </button>
      </div>
      <div className="col-md-4 d-flex align-items-end">
        <button type="button" className="btn btn-secondary w-100" onClick={() => reset()}>
          Reset
        </button>
      </div>
    </form>
  );
};